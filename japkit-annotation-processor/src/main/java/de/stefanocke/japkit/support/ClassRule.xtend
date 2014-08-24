package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenAnnotationMirror
import de.stefanocke.japkit.gen.GenAnnotationType
import de.stefanocke.japkit.gen.GenAnnotationValue
import de.stefanocke.japkit.gen.GenClass
import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenEnum
import de.stefanocke.japkit.gen.GenExecutableElement
import de.stefanocke.japkit.gen.GenExtensions
import de.stefanocke.japkit.gen.GenInterface
import de.stefanocke.japkit.gen.GenPackage
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.support.el.ELSupport
import de.stefanocke.japkit.support.el.ELVariableRule
import java.util.List
import java.util.Set
import javax.annotation.processing.ProcessingEnvironment
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ElementKind
import javax.lang.model.element.Modifier
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror

@Data
class ClassRule {
	protected val extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	protected val extension ProcessingEnvironment = ExtensionRegistry.get(ProcessingEnvironment)
	protected val extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	protected val extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	protected val extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	protected val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	protected val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	protected val extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	protected val extension TypeResolver = ExtensionRegistry.get(TypeResolver)
	protected val extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
	protected val extension RuleUtils = ExtensionRegistry.get(RuleUtils)
	
	AnnotationMirror metaAnnotation
	TemplateRule templateRule
	MembersRule membersRule
	ElementKind kind
	()=>Set<Modifier> modifiersRule	
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	boolean isTopLevelClass	
	ClassNameRule nameRule
	BehaviorDelegationRule behaviorRule
	
	()=>TypeMirror superclassRule
	List<()=>TypeMirror> interfaceRules
	
	boolean shallCreateShadowAnnotation
	
	List<ELVariableRule> varRules
		
	
	new(AnnotationMirror metaAnnotation, TypeElement templateClass, boolean isTopLevelClass){
		_metaAnnotation = metaAnnotation
		_templateRule= templateClass?.createTemplateRule
		_membersRule = new MembersRule(metaAnnotation)
		_kind = metaAnnotation.value('kind', ElementKind)
		_modifiersRule = createModifiersRule(metaAnnotation, templateClass, null)
		
		//TODO: Das template wird hier nicht mit hineingegeben, da die Template rule bereits selbst die annotationen des Templates kopiert.
		//Es gibt recht viele Redundanzen zwischen @InnerClass und @Template. Vielleicht lässt sich das zusammenführen... z.B. könnte die @InnerClass
		//Annotation STATT @Template verwendet werden. Das wäre dann aber auch für @Clazz zu überlegen. 
		_annotationsRule = createAnnotationMappingRules(metaAnnotation, null, null)
		
		_shallCreateShadowAnnotation = metaAnnotation.value("createShadowAnnotation", Boolean) ?: false
		_isTopLevelClass = isTopLevelClass
		_nameRule = if(isTopLevelClass) new ClassNameRule(metaAnnotation) else null
		_behaviorRule = new BehaviorDelegationRule(metaAnnotation)
		_superclassRule = createTypeRule(metaAnnotation, null, "superclass", null, null)
		_interfaceRules = (1 .. 2).map[createTypeRule(metaAnnotation, null, '''interface«it»''', null, null)].toList
		
		//Supports ELVariables in the scope of the generated class. For inner classes, this is already done in the inner class rule
		//Note: src expression is currently not supported in the annotation, since generating multiple classes is not supported
		//and would for instance be in conflict with ElementExtensions.generatedTypeElementAccordingToTriggerAnnotation 
		_varRules = if(isTopLevelClass) createELVariableRules(metaAnnotation, null) else null;
	}
	
	/**
	 * Generates a top level or inner class and potentially some auxillary classes.
	 * 
	 * @return the set of generated top level classes. 
	 */
	def GenTypeElement generateClass(String name, Set<GenTypeElement> generatedTopLevelClasses
	) {
		val enclosingClass = currentGeneratedClass
		
		if(isTopLevelClass != (enclosingClass==null)){
			throw new IllegalArgumentException("currentGeneratedClass must be available when it is a rule for an inner class.")
		}
		
		pushCurrentMetaAnnotation(metaAnnotation)
		try {
			scope[
				varRules?.forEach[it.putELVariable]
				//superclass with type args
				val generatedClass = createClass(enclosingClass, name)
				
				
				//Register generated class as early as possible to allow error type resolution in other classes
				registerGeneratedTypeElement(generatedClass, currentAnnotatedClass, if(isTopLevelClass) currentTriggerAnnotation else null)	
		
			 
				setCurrentGeneratedClass(generatedClass)
				
				generatedClass.modifiers = modifiersRule.apply
				
				//TODO: Move to modifiers rule ?
				if(templateRule != null){
					generatedClass.removeModifier(Modifier.ABSTRACT) //Templates are usually abstract
				}
				
				generatedClass.setSuperclass(superclassRule.apply)
				interfaceRules.map[apply].filter[it!=null].forEach[
					generatedClass.addInterface(it)
				]
				
				if(isTopLevelClass){
					createShadowAnnotation(generatedClass)	
				}
				
				
				generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)
				
				
				membersRule.apply(generatedClass)
				
				
				//For @InnerClass, the annotated inner class is the template
				templateRule?.apply(generatedClass)
								
				behaviorRule.createBehaviorDelegation(generatedClass)
				
				if(isTopLevelClass){
					val Set<GenTypeElement> generatedClasses = newHashSet
					generatedClasses.add(generatedClass)	
					addAllAuxTopLevelClasses(generatedClasses, generatedClass)
	
					generatedClasses.forEach[markAsGenerated(it, currentAnnotatedClass)]
					generatedClasses.forEach[addOrderAnnotations]				
					generatedClasses.forEach[addParamNamesAnnotations]		
				
				
					if(generatedTopLevelClasses!=null){
						generatedTopLevelClasses.addAll(generatedClasses)			
					}
				
				}
			
				generatedClass
			
			]
		
		} finally {
			
			popCurrentMetaAnnotation
		}
	}
	
	def void addAllAuxTopLevelClasses(Set<GenTypeElement> result, GenTypeElement typeElement) {
		result.addAll(typeElement.auxTopLevelClasses)
		typeElement.declaredTypes.forEach[addAllAuxTopLevelClasses(result, it as GenTypeElement)]
	}
	
	
	
	def createShadowAnnotation(GenTypeElement generatedClass) {
		try{
			
			if(shallCreateShadowAnnotation){
				val shadowAnnotation = GenExtensions.copy(currentTriggerAnnotation) => [it.setShadowIfAppropriate]
				
				valueStack.getVariablesForShadowAnnotation().forEach[name, value |
					shadowAnnotation.setValue(name, [t| 
						//TODO: Schicker. In extension o.ä verlagern
						new GenAnnotationValue(coerceAnnotationValue(value, t))
					])
				]
				
				generatedClass.addAnnotationMirror(shadowAnnotation)
				//put on value stack
				putShadowAnnotation(shadowAnnotation)
			}
		
		} 
		catch (TypeElementNotFoundException tenfe) {
			throw tenfe
		}
		catch (RuntimeException re){
			reportError('''Error when creating shadow annotation:''', re, null, null, null)
		}
	}

	private def void addOrderAnnotations(Element e) {
		val enclosed = e.enclosedElements
		for (order : 0 ..< enclosed.size) {
			enclosed.get(order).addOrderAnnotation(order);
			enclosed.get(order).addOrderAnnotations()
		}
	}

	def dispatch void addOrderAnnotation(GenElement element, Integer order) {
		element.addAnnotationMirror(
			new GenAnnotationMirror(elementUtils.getTypeElement(ORDER_ANNOTATION_NAME).asType as DeclaredType) => [
				setValue("value", [new GenAnnotationValue(order)])
			]
		)
	}

	def dispatch void addOrderAnnotation(Element element, Integer integer) {
	}
	
	
	def dispatch void addParamNamesAnnotations(GenTypeElement typeElement) {
		typeElement.enclosedElements.forEach[it.addParamNamesAnnotations]
	}
	
	def dispatch void addParamNamesAnnotations(GenExecutableElement element) {
		if(!element.parameters.nullOrEmpty){
			element.addAnnotationMirror(
				new GenAnnotationMirror(elementUtils.getTypeElement(PARAM_NAMES_ANNOTATION_NAME).asType as DeclaredType) => [
					setValue("value", [new GenAnnotationValue(element.parameters.map[simpleName.toString].map[new GenAnnotationValue(it)].toList)])
				]
			)		
		}
	}
	def dispatch void addParamNamesAnnotations(Element element) {
		
	}
	
	
	def GenTypeElement createClass(GenTypeElement enclosingClass, String name
	) {
		
		val enclosingElAndClassName = if(isTopLevelClass){
			GenPackage.forName(nameRule.generatePackageName(currentAnnotatedClass.packageOf)) -> nameRule.generateClassName(currentAnnotatedClass)
		} else {
			//For inner classes, use provided class name
			enclosingClass -> name
		}		

		val generatedClass = switch (kind) {
			case ElementKind.CLASS:
				new GenClass(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.ENUM:
				new GenEnum(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.INTERFACE:
				new GenInterface(enclosingElAndClassName.value, enclosingElAndClassName.key)
			case ElementKind.ANNOTATION_TYPE:
				new GenAnnotationType(enclosingElAndClassName.value, enclosingElAndClassName.key)
			default:
				throw new ProcessingException('''Invalid element kind in GenClass annotation: «kind»''',
					currentAnnotatedClass)
		}


		generatedClass
	}


}