package de.stefanocke.japkit.rules

import de.stefanocke.japkit.el.ELSupport
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind
import de.stefanocke.japkit.model.GenUnresolvedType
import de.stefanocke.japkit.services.ExtensionRegistry
import de.stefanocke.japkit.services.TypeElementNotFoundException
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import org.eclipse.xtend.lib.annotations.Data
import java.util.Set

@Data
class TypeRule extends AbstractNoArgFunctionRule<TypeMirror> {
	
	ClassSelectorKind kind
	Set<TypeMirror> requiredTriggerAnnotation
	TypeMirror enclosing
	String expr
	String lang
	//this rule refers directly to a var on value stack, since no expression is set
	boolean isVarRef
	
	new(AnnotationMirror metaAnnotation, TypeElement typeElement){
		super(metaAnnotation, typeElement, TypeMirror)
		kind= metaAnnotation.value("kind", ClassSelectorKind)		
		requiredTriggerAnnotation = metaAnnotation.value("requiredTriggerAnnotation", typeof(TypeMirror[])).toSet
		enclosing = metaAnnotation.value("enclosing", TypeMirror)
		lang = metaAnnotation.value("lang", String)
		
		val exprFromAV = metaAnnotation.value("expr", String);
		isVarRef = (kind == ClassSelectorKind.EXPR) && exprFromAV.nullOrEmpty  //TODO: Maybe for this case there could be a more generic @VarRef annotation.
		
		expr = if(isVarRef) typeElement.simpleName.toString.toFirstLower else exprFromAV
	}
	
	override protected TypeMirror evalInternal() {
		

		val resolvedSelector = new ResolvedClassSelector

		resolvedSelector.kind = this.kind
		switch (kind) {
			case ClassSelectorKind.NONE:
				resolvedSelector.type = null
			case ClassSelectorKind.ANNOTATED_CLASS:
				resolvedSelector.type = currentAnnotatedClass?.asType
			case ClassSelectorKind.GENERATED_CLASS:
				resolvedSelector.type = currentGeneratedClass?.asType
			case ClassSelectorKind.SRC_TYPE:
				resolvedSelector.type = currentSrc.srcType
			case ClassSelectorKind.SRC_SINGLE_VALUE_TYPE:
				resolvedSelector.type = currentSrc.srcType?.singleValueType
			case ClassSelectorKind.INNER_CLASS_NAME:
			{	
				resolveInnerClassSelector(resolvedSelector)	
			}
			
			case ClassSelectorKind.EXPR : {
				resolvedSelector.type = evalClassSelectorExpr(resolvedSelector, TypeMirror)
			}
			case ClassSelectorKind.FQN : {
				val fqn = evalClassSelectorExpr(resolvedSelector, String)
				resolvedSelector.type = findTypeElement(fqn)?.asType
				if(resolvedSelector.type == null){
					resolvedSelector.type = new GenUnresolvedType(fqn, false)
				}
			}
			default: {
				resolvedSelector.type = null
				reportRuleError('''Selector «resolvedSelector.kind» not supported''')
			}
				
		}

	
		
		if (!requiredTriggerAnnotation.nullOrEmpty && resolvedSelector.type !=null) {
			resolvedSelector.type = generatedTypeAccordingToTriggerAnnotation(resolvedSelector.type, requiredTriggerAnnotation, true)
		}
		
		
		resolvedSelector.type
	}
	
	
	private def getEnclosingTypeElement() {
		val extension TypeResolver = ExtensionRegistry.get(TypeResolver)
		enclosing?.resolveType?.asTypeElement
	}
	
	private def resolveInnerClassSelector(ResolvedClassSelector resolvedSelector) {
		resolvedSelector.enclosingTypeElement = getEnclosingTypeElement()
		if(resolvedSelector.enclosingTypeElement==null){
			reportRuleError('''Could not determine enclosing type element for inner class.''')
			return
		}
		resolvedSelector.innerClassName = evalClassSelectorExpr(resolvedSelector, String)
		
		//simple name of the type template as fallback
		if(resolvedSelector.innerClassName==null){
			resolvedSelector.innerClassName=metaElement.simpleName.toString
		}
		
		resolvedSelector.typeElement = resolvedSelector.enclosingTypeElement.declaredTypes.findFirst[simpleName.contentEquals(resolvedSelector.innerClassName)]
		resolvedSelector.type = if(resolvedSelector.typeElement != null)
			resolvedSelector.typeElement.asType
			else new GenUnresolvedType('''«resolvedSelector.enclosingTypeElement.qualifiedName».«resolvedSelector.innerClassName»''', true)
	}
	
	private def <T> T evalClassSelectorExpr(ResolvedClassSelector resolvedSelector, Class<T> targetType) {
		
		if(expr.nullOrEmpty) return null
		
		ExtensionRegistry.get(ELSupport).eval(expr, lang, targetType,
			'''Error when evaluating class selector expression '«expr»'  ''', null			
		)	
		
	}
	

	
	/**
	 * Validates if the type has (at most) one of the given trigger annotations. If so , and it is not a generated type, 
	 * the according generated type is determined and returned.  
	 */
	def private TypeMirror generatedTypeAccordingToTriggerAnnotation(TypeMirror type, Iterable<TypeMirror> triggerAnnotationTypes, boolean mustHaveTrigger
	) {
		var typeCandidate = type
		
		if (typeCandidate instanceof DeclaredType && !(typeCandidate instanceof ErrorType)) {
			
			
			val typeElement = typeCandidate.asTypeElement
			typeCandidate = 
			generatedTypeElementAccordingToTriggerAnnotation(typeElement, triggerAnnotationTypes, mustHaveTrigger)?.asType
		}
		typeCandidate
	}
	
	def private TypeElement generatedTypeElementAccordingToTriggerAnnotation(TypeElement typeElement, Iterable<TypeMirror> triggerAnnotationTypes, boolean mustHaveTrigger) {
		if(triggerAnnotationTypes.nullOrEmpty){
			return typeElement
		}
		
		val extension AnnotationExtensions = ExtensionRegistry.get(AnnotationExtensions)
		if(typeElement.annotationMirrors.filter[isTriggerAnnotation].empty){
			//If the type element has no trigger annotations at all we assume it is a "hand-written" class and leave it as it is.
			//TODO: This could be configurable...
			return typeElement
		}
		
		
		val triggerAnnotationTypeFqns = triggerAnnotationTypes.map[qualifiedName].toSet
		val annotations = typeElement.annotationMirrors.filter[triggerAnnotationTypeFqns.contains(annotationType.qualifiedName)] 
		
		if (annotations.empty) {
			if (mustHaveTrigger) {
				reportRuleError(
					'''Related type «typeElement.qualifiedName» must have one of the trigger annotations «triggerAnnotationTypeFqns».''');
				null

			} else {
				typeElement
			}
		}
		
		else if (annotations.size > 1) {
		
			reportRuleError(
				'''Related type «typeElement.qualifiedName» has more than one of the trigger annotations «triggerAnnotationTypeFqns».
				 Thus, the generated type to use is not unique.''');
			null
		}
		else if(!typeElement.generated) {  
		
			//Only apply the transformation if it is not a generated class 
				
			
			val triggerAnnotation = annotations.head

			val rule = ExtensionRegistry.get(RuleFactory).createTriggerAnnotationRule(triggerAnnotation.annotationAsTypeElement)
			val fqn = rule.getGeneratedTypeElementFqn(typeElement)
			
			val generatedTypeElement = findTypeElement(fqn)
			if (generatedTypeElement == null) {
				throw new TypeElementNotFoundException(fqn, '')  
			} else {
				generatedTypeElement				
			}
				
		} else {
			typeElement
		}
	}
	
}