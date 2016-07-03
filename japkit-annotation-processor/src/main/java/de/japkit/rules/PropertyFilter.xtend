package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.metaannotations.Properties
import de.japkit.model.Property
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.MessageCollector
import de.japkit.services.TypesRegistry
import java.util.Collection
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

@Data
class PropertyFilter extends AbstractFunctionRule<List>{
	val transient extension ElementsExtensions jme = ExtensionRegistry.get(ElementsExtensions)
	val transient extension MessageCollector messageCollector = ExtensionRegistry.get(MessageCollector)
	val transient extension RuleFactory = ExtensionRegistry.get(RuleFactory)
	val transient extension JavaBeansExtensions javaBeansExtensions = ExtensionRegistry.get(JavaBeansExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension TypeResolver typesResolver = ExtensionRegistry.get(TypeResolver)
	val transient extension ELSupport = ExtensionRegistry.get(ELSupport)

	TypeMirror sourceClass
	String includeNamesExpr
	String includeNamesLang
	String includeNamesPrefix 
	String includeNamesSuffix 
	List<ElementMatcher> includeRules
	List<ElementMatcher> excludeRules
	Properties.RuleSource ruleSource

	boolean fromFields;


	
	/**
	 * Property source is determined by AV "sourceClass"
	 */
	def List<Property> getFilteredProperties() {
		//TODO: Cleanup TENFE handling?
		val propertySource = handleTypeElementNotFound(null,
			'''Could not find property source. No properties will be generated.''') [
			sourceClass?.resolveType?.asTypeElement
		]
		if (propertySource != null) {
			handleTypeElementNotFound(emptyList,
				'''Could not determine properties of source «propertySource.qualifiedName».''') [
				getFilteredProperties(propertySource)
			]
		} else {
			val TypeElement src = if (currentSrc instanceof TypeElement)
					currentSrc as TypeElement
				else if (currentSrc instanceof DeclaredType)
					(currentSrc as DeclaredType).asTypeElement
				else {
					reportRuleError(
						'''Could not determine properties of source «currentSrc», since it is neither a TypeElement nor a declared type.''')
					return emptyList
				}		
			
			handleTypeElementNotFound(emptyList,
				'''Could not determine properties of source «currentSrc».''') [
				getFilteredProperties(src)
			]
		
		}
	}

	def List<Property> getFilteredProperties(TypeElement propertySource) {

		val properties = propertySource.properties(Object.name, fromFields)
		
		val includeNames = if(includeNamesExpr.nullOrEmpty) emptyList 
			else eval(includeNamesExpr, includeNamesLang, Collection, '''IncludeNamesExpr could not be evaluated: «includeNamesExpr»''', emptyList).
			map[
				//support for using (inner) classes to refer to properties.
				//Reason: Eclipse always returns "unknown" if the class containig a string constant is not available when used in an annotation value.
				//For class typed AVs we at least get the simple name of the class.
				//TODO: Support nested paths for deep traversing?  
				if(it instanceof TypeMirror) it.asTypeElement.simpleName.toString().toFirstLower else it as String
			].map[
				it.substring(includeNamesPrefix.length, it.length - includeNamesSuffix.length)
			].toList
		
		includeNames.forEach [
			if (!properties.exists[p|it.equals(p.name)]) {
				reportRuleError('''Property with name «it» does not exist in source class.''')
			}
		]

		properties.filter [
			includeRules.exists[r|r.matches(getSourceElement(ruleSource))] || includeNames.contains(name)
		].filter[excludeRules.forall[r|!r.matches(getSourceElement(ruleSource))]].toList
	}

	new(AnnotationMirror metaAnnotation){
		this(metaAnnotation, null)	
	}
	
	new(AnnotationMirror metaAnnotation, Element element) {
		super(metaAnnotation, element, List)

		sourceClass = metaAnnotation.value("sourceClass", TypeMirror)
		includeNamesExpr = metaAnnotation.value("includeNamesExpr", String)
		includeNamesLang = metaAnnotation.value("includeNamesLang", String)
		
		includeNamesPrefix =  metaAnnotation.value("includeNamesPrefix", String) ?: ""
		includeNamesSuffix = metaAnnotation.value("includeNamesSuffix", String) ?: ""
		includeRules = metaAnnotation.value("includeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		excludeRules = metaAnnotation.value("excludeRules", typeof(AnnotationMirror[])).map[
			createElementMatcher(it)]
		ruleSource = metaAnnotation.value("ruleSource", Properties.RuleSource)
		fromFields = metaAnnotation.value("fromFields", Boolean)
	}
	
	override protected evalInternal() {
		filteredProperties
	}
	
}
