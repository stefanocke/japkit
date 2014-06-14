package de.stefanocke.japkit.processor

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenClass
import de.stefanocke.japkit.gen.GenEnum
import de.stefanocke.japkit.gen.GenInterface
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.MemberGeneratorAnnotation
import de.stefanocke.japkit.support.AnnotationExtensions
import de.stefanocke.japkit.support.ClassNameRule
import de.stefanocke.japkit.support.ElementsExtensions
import de.stefanocke.japkit.support.ExtensionRegistry
import de.stefanocke.japkit.support.GenerateClassContext
import de.stefanocke.japkit.support.MessageCollector
import de.stefanocke.japkit.support.ProcessingException
import de.stefanocke.japkit.support.RelatedTypes
import de.stefanocke.japkit.support.RuleFactory
import de.stefanocke.japkit.support.TypeElementNotFoundException
import de.stefanocke.japkit.support.TypesExtensions
import de.stefanocke.japkit.support.TypesRegistry
import de.stefanocke.japkit.support.el.ELSupport
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.ServiceLoader
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import javax.tools.Diagnostic.Kind

class ClassGeneratorSupport {
	protected val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	protected val extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	protected val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	protected val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	protected val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	protected val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	protected val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	protected val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	protected val extension RelatedTypes = ExtensionRegistry.get(RelatedTypes)
	protected val extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	
	protected BehaviorDelegationGenerator behaviorDelegationGenerator = new BehaviorDelegationGenerator
	
	def GenTypeElement createClass(TypeElement annotatedClass, AnnotationMirror am, AnnotationMirror genClass) {
		val nameRule = new ClassNameRule(am, genClass)
		val genClassName = nameRule.generateClassName(annotatedClass)
		val genClassPackageName = nameRule.generatePackageName(annotatedClass.packageOf)

		val kind = am.valueOrMetaValue(annotatedClass, 'kind', ElementKind, genClass)

		val generatedClass = switch (kind) {
			case ElementKind.CLASS:
				new GenClass(genClassName, genClassPackageName)
			case ElementKind.ENUM:
				new GenEnum(genClassName, genClassPackageName)
			case ElementKind.INTERFACE:
				new GenInterface(genClassName, genClassPackageName)
			default:
				throw new ProcessingException('''Invalid element kind in GenClass annotation: «kind»''',
					annotatedClass)
		}

		setModifiers(generatedClass, am, genClass)

		generatedClass
	}
	
	def protected mapTypeAnnotations(TypeElement annotatedClass, AnnotationMirror triggerAnnotation, AnnotationMirror genClassAnnotation, 
		List<GenAnnotationMirror> existingAnnotations) {
		val annotationMappings = triggerAnnotation.valueOrMetaValue(annotatedClass, "annotationMappings", typeof(AnnotationMirror[]),
			genClassAnnotation).map[createAnnotationMappingRule(it)]
		mapAnnotations(annotatedClass, annotationMappings, existingAnnotations)
	}
	
	def protected setModifiers(GenTypeElement generatedClass, AnnotationMirror triggerAnnotation, AnnotationMirror genClassAnnotation) {
		val modifier = triggerAnnotation.valueOrMetaValue("modifier", typeof(Modifier[]), genClassAnnotation)
		
		generatedClass => [
			modifier.forEach[m|addModifier(m)]
		]
	}
	
		def setSuperClassAndInterfaces(TypeElement annotatedClass, GenTypeElement generatedClass, AnnotationMirror am,
		AnnotationMirror genClass) {
		val superclass = relatedType(annotatedClass, generatedClass, am, "superclass", genClass, annotatedClass) as DeclaredType ->
			relatedTypes(annotatedClass, generatedClass, am, "superclassTypeArgs", genClass, annotatedClass) //interfaces with type args
		val interfaces = (1 .. 2).map[i|
			relatedType(annotatedClass, generatedClass, am, '''interface«i»''', genClass, annotatedClass) as DeclaredType ->
				relatedTypes(annotatedClass, generatedClass, am, '''interface«i»TypeArgs''', genClass, annotatedClass)].filter[
			key != null].toList

		generatedClass => [
			setSuperclass(superclass.key, superclass.value)
			interfaces.forEach[i|addInterface(i.key, i.value)]
		]
	}

	def protected processMemberGenerators(TypeElement annotatedClass, GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation, AnnotationMirror genClassMetaAnnotation) {

		val membersAnnotationRefs = triggerAnnotation.valueOrMetaValue(annotatedClass, "members",
			typeof(AnnotationMirror[]), genClassMetaAnnotation)

		//For each @Members annotation, we get the class referred by its AV "value". That class has the member annotations to process.
		membersAnnotationRefs.forEach [
			val typeWithMemberAnnotations = triggerAnnotation.valueOrMetaValue("value", TypeMirror, it)
			val activation = triggerAnnotation.elementMatchers("activation", it)
			if (activation.nullOrEmpty || activation.exists[matches(annotatedClass)]) {
				val te = if (!typeWithMemberAnnotations.isVoid)
						typeWithMemberAnnotations.asTypeElement
					else
						triggerAnnotation.annotationAsTypeElement
				printDiagnosticMessage(['''Process member annotations on «te»'''])
				te.annotationMirrors.forEach [
					processMemberGenerator(te, annotatedClass, generatedClass, triggerAnnotation, genClassMetaAnnotation)
				]

			}
		]

	}

	def protected void processMemberGenerator(
		AnnotationMirror memberGeneratorMetaAnnotation,
		TypeElement membersClass,
		TypeElement annotatedClass,
		GenTypeElement generatedClass,
		AnnotationMirror triggerAnnotation,
		AnnotationMirror genClassMetaAnnotation
	) {
		if (memberGeneratorMetaAnnotation.equals(genClassMetaAnnotation)) {
			return;
		}

		try {

			pushCurrentMetaAnnotation(memberGeneratorMetaAnnotation)

			val annoType = memberGeneratorMetaAnnotation.annotationType
			val annoTypeElement = annoType.asTypeElement
			val triggerAnnotationTypeElement = if (annoTypeElement.simpleName.contentEquals("List")) {

					//Support for multiple trigger annotations of same type, wrapped in a List annotation.
					val valueAvType = annoTypeElement.declaredMethods.findFirst[simpleName.contentEquals('value')]?.
						returnType
					if (valueAvType instanceof ArrayType) {
						(valueAvType as ArrayType).componentType.asTypeElement
					} else
						annoTypeElement

				} else {
					annoTypeElement
				}
				
			if(triggerAnnotationTypeElement.annotationMirror(MemberGeneratorAnnotation) == null){
				//No Member generator annotation
				return
			}

			val triggerFqn = triggerAnnotationTypeElement.qualifiedName.toString
			val MemberGenerator mg = getMemberGenerator(triggerFqn);
			if (mg != null) {
				if (triggerAnnotationTypeElement != annoTypeElement) {
					val avList = memberGeneratorMetaAnnotation.value("value", typeof(AnnotationMirror[]))
					avList.forEach [
						try {
							mg.createMembers(membersClass, annotatedClass, generatedClass, triggerAnnotation, it)
						} catch (TypeElementNotFoundException e) {
							handleTypeElementNotFound(
								'''Error while member generator «mg.class» processes meta annotation «it»: «e.message»''',
								e.fqn, annotatedClass)
						}
					]
				} else {
					try {
						mg.createMembers(membersClass, annotatedClass, generatedClass, triggerAnnotation,
							memberGeneratorMetaAnnotation)
					} catch (TypeElementNotFoundException e) {
						handleTypeElementNotFound(
							'''Error while member generator «mg.class» processes meta annotation «memberGeneratorMetaAnnotation»: «e.
								message»''', e.fqn, annotatedClass)
					}

				}
			} else {
				if (!triggerFqn.startsWith("java.lang.")) {
					messager.printMessage(Kind.WARNING,
						'''No MemberGenerator found for meta annotation «triggerFqn».''', annotatedClass,
						triggerAnnotation)
				}
			}

		} finally {
			popCurrentMetaAnnotation
		}
	}

	static val builtInMemberGenerators = #{
		PropertiesGenerator,
		ConstructorGenerator,
		MethodGenerator,
		FromTemplateGenerator,
		AnnotationGenerator
	}
	static var Map<String, MemberGenerator> memberGenerators;

	def static MemberGenerator getMemberGenerator(String metaAnnotationFqn) {
		if (memberGenerators == null) {
			memberGenerators = new HashMap();
			ServiceLoader.load(MemberGenerator, MemberGenerator.classLoader).forEach[
				memberGenerators.put(it.supportedMetaAnnotation, it)]
			builtInMemberGenerators.forEach[val generator = newInstance
				memberGenerators.put(generator.supportedMetaAnnotation, generator)]
			System.out.println(memberGenerators)
		}
		memberGenerators.get(metaAnnotationFqn)
	}
}