package de.japkit.rules

import de.japkit.metaannotations.AVMode
import de.japkit.model.GenAnnotationMirror
import de.japkit.model.GenAnnotationValue
import de.japkit.rules.RuleException
import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.Set
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data

import static extension de.japkit.rules.RuleUtils.withPrefix

@Data
class AnnotationValueMappingRule extends AbstractRule {

	()=>boolean activationRule
	String name
	Object value
	String expr
	//the avName used for error reporting (one of expr, annotationMappingId or value)
	String errorAvName
	String lang
	()=>AnnotationMappingRule lazyAnnotationMapping
	AVMode mode
	((Object)=>Object)=>Iterable<Object> scopeRule
	
	String avPrefix

	def GenAnnotationValue mapAnnotationValue(GenAnnotationMirror annotation, TypeMirror avType) {
		inRule[
			//existing value (without considering defaults!)
			val existingValue = annotation?.getValueWithoutDefault(name)
			
			if(!activationRule.apply){
				return existingValue
			}
	
			if (existingValue !== null) {
				switch (mode) {
					case AVMode.ERROR_IF_EXISTS:
						throw new RuleException(
							'''The annotation value «name» was already generated by another rule and the mapping mode is «mode».''')
					case AVMode.IGNORE:
						return existingValue
					case AVMode.REMOVE:
						return null
					case AVMode.REPLACE: { /**Nothing to do but continue. */
					}
					case AVMode.JOIN_LIST: { /**Nothing to do but here. TODO: After calculating the new value, apply the "join" */
					}
					case AVMode.MERGE:{
						
					}
				}
			}
			
			//If this AV-Mapping is not completely initialized, return the value unchanged.
			//Is relevant for annotation templates. There AVMRs are created for each AV.
			// Could be optimized by dropping the ones that are "empty", since neither expr nor value nor annotationMapping is set.
			if(value === null && expr === null && lazyAnnotationMapping === null) {
				return existingValue;
			}
	
			val v = handleException(null, errorAvName) [
				val flatValues = newArrayList

				scopeRule.apply [
					if (value !== null) {
						value
					} else if (lazyAnnotationMapping !== null) {

						val annotationMapping = lazyAnnotationMapping.apply

						val annotations = newArrayList
						annotationMapping.mapOrCopyAnnotations(annotations)
						annotations as ArrayList<? extends Object>

					} else if (expr !== null) {
						evaluateExpression(avType, expr)
					} else {
						throw new IllegalStateException("Annotation value could not be determined, since none of value, expr or lazyAnnotationMapping is set.");
					}
				]?.forEach[if(it instanceof Iterable<?>) flatValues.addAll(it) else flatValues.add(it)]

				coerceAnnotationValue(flatValues, avType)

			]
	
			if(v === null){
				return existingValue;  //No value... Leave existing value unchanged.
			}
			
			if (mode == AVMode.JOIN_LIST && existingValue !== null) {
				val joined = new ArrayList(existingValue.valueWithErrorHandling as List<Object>)
				joined.addAll(v as List<Object>)
				new GenAnnotationValue(joined)
			} else {
				new GenAnnotationValue(v)
			}
		
		]

	}

	def private Object evaluateExpression(TypeMirror avType, String expr) {

		val targetClass = if(avType.kind.isPrimitive) avType.toAnnotationValueClass else Object	
		eval(expr, lang, targetClass, "expr".withPrefix(avPrefix), null)

	}


	new(AnnotationMirror a,  Map<String, AnnotationMappingRule> mappingsWithId) {
		super(a, null)
		avPrefix=''
		name = a.value("name", String)
		
		val setAvNames = newHashSet
		
		value = a.valueAndRemember("value", String, setAvNames)
		expr = a.valueAndRemember("expr", String, setAvNames)	
		lang = a.value("lang", String)
		mode = a.value("mode", AVMode)
		val annotationMappingId = a.valueAndRemember("annotationMappingId", String, setAvNames)
		
		lazyAnnotationMapping = if(annotationMappingId.nullOrEmpty) null else [| 
			val amr = mappingsWithId.get(annotationMappingId)
			if(amr === null){
				throw new RuleException("Annotation Mapping with id "+annotationMappingId+" not found");
			}
			amr
		]

		errorAvName = atMostOneAvName(setAvNames, true)
		activationRule = createActivationRule(a, null)
		scopeRule = createScopeRule(a, null, null)

	}
	
	new(AnnotationMirror a,  Element templateElement, String avName) {
		super(a, templateElement)
		name = avName
		
		val setAvNames = newHashSet
		
		value = a.valueAndRemember(avName, Object, setAvNames)

		avPrefix = avName+'_'

		expr = a.valueAndRemember("expr".withPrefix(avPrefix), String, setAvNames)
		lang = a.value("lang".withPrefix(avPrefix), String)
		mode = AVMode.JOIN_LIST
		
		
		val annotationMappingAnnotation =  a.valueAndRemember(avPrefix, AnnotationMirror, setAvNames)
		
		lazyAnnotationMapping = if (annotationMappingAnnotation === null) null else {
			val amr = new AnnotationMappingRule(annotationMappingAnnotation, templateElement);
			[| amr]
		}
		
		errorAvName = atMostOneAvName(setAvNames, false)		
		activationRule = createActivationRule(a, avPrefix)
		scopeRule = createScopeRule(a, null, avPrefix)

	}
	
	private def <T> T valueAndRemember(AnnotationMirror am, String avName, Class<T> avType, Set<String> setAvNames) {
		val v = am.value(avName, avType)
		if(v !== null) {
			setAvNames.add(avName)
		}
		v
	} 
	
	private def atMostOneAvName(Set<String> setAvNames, boolean required) {
		if(setAvNames.size > 1) {
			throw ruleException('''At most one of the annotation values «setAvNames.join(', ')» must be set.''')
		}
		if(required && setAvNames.empty) {
			throw ruleException('''At least one of the annotation values «setAvNames.join(', ')» must be set.''')
		}
		setAvNames.head
	}

}
