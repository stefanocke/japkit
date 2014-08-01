package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenElement
import de.stefanocke.japkit.gen.GenTypeElement
import de.stefanocke.japkit.metaannotations.Constructor
import de.stefanocke.japkit.metaannotations.Field
import de.stefanocke.japkit.metaannotations.InnerClass
import de.stefanocke.japkit.metaannotations.Method
import de.stefanocke.japkit.metaannotations.Template
import de.stefanocke.japkit.support.el.ELSupport
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import org.eclipse.xtext.xbase.lib.Functions.Function1

@Data
class TemplateRule implements Function1<GenTypeElement, List<? extends GenElement>>{

	protected extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val extension ELSupport elSupport = ExtensionRegistry.get(ELSupport)
	val extension GenerateClassContext = ExtensionRegistry.get(GenerateClassContext)
	val RuleUtils ru = ExtensionRegistry.get(RuleUtils)

	TypeElement templateClass
	AnnotationMirror templateAnnotation
	List<ConstructorRule> constructorRules
	List<MethodRule> methodRules
	List<FieldRule> fieldRules
	List<InnerClassRule> innerClassRules
	(GenElement)=>List<? extends AnnotationMirror> annotationsRule
	((Object)=>Iterable<? extends GenElement>)=>Iterable<Iterable<? extends GenElement>> scopeRule

	new(TypeElement templateClass, AnnotationMirror templateAnnotation) {
		_templateClass = templateClass
		_templateAnnotation = templateAnnotation ?: templateClass.annotationMirror(Template)
		_methodRules = templateClass.declaredMethods.map[it -> annotationMirror(Method)].filter[value != null].map [
			new MethodRule(value, key)
		].toList
		
		_constructorRules = templateClass.declaredConstructors.map[it -> annotationMirror(Constructor)].filter[value != null].map [
			new ConstructorRule(value, key)
		].toList

		_fieldRules = templateClass.declaredFields.map [
			new FieldRule(annotationMirror(Field), it)
		]
		
		_innerClassRules = templateClass.declaredTypes.map[it -> annotationMirror(InnerClass)].filter[value != null].map [
			new InnerClassRule(value, key)
		].toList
		
		_annotationsRule=ru.createAnnotationMappingRules(templateAnnotation, templateClass, null)
		_scopeRule=ru.createScopeRule(templateAnnotation, null)

	}

	override apply(GenTypeElement generatedClass) {
		
			
		scopeRule.apply [
			
			generatedClass.annotationMirrors = annotationsRule.apply(generatedClass)

			addInterfaces(generatedClass)
			
			val generatedMembers = newArrayList
			
			innerClassRules.forEach [generatedMembers.addAll(it.apply(generatedClass))]
			fieldRules.forEach [generatedMembers.addAll(it.apply(generatedClass))]
			constructorRules.forEach [generatedMembers.addAll(it.apply(generatedClass))]
			methodRules.forEach [generatedMembers.addAll(it.apply( generatedClass))]		
			
			generatedMembers
		].flatten.toList

	}

	def addInterfaces(GenTypeElement generatedClass) {
		templateClass.interfaces.forEach [
			generatedClass.addInterface(it.resolveType) //TODO: Check , if interface already exists? 
		]
	}
}