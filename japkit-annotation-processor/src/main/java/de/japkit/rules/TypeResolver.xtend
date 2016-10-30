package de.japkit.rules

import de.japkit.model.GenArrayType
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.GenerateClassContext
import de.japkit.services.MessageCollector
import de.japkit.services.TypeElementNotFoundException
import de.japkit.services.TypesExtensions
import de.japkit.services.TypesRegistry
import java.util.List
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.TypeElement
import javax.lang.model.type.ArrayType
import javax.lang.model.type.DeclaredType
import javax.lang.model.type.ErrorType
import javax.lang.model.type.TypeMirror
import de.japkit.model.GenDeclaredType

/**Resolves type references / class selectors from templates and annotations.*/
class TypeResolver {
	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension TypesExtensions = ExtensionRegistry.get(TypesExtensions)
	val transient extension TypesRegistry = ExtensionRegistry.get(TypesRegistry)
	val transient extension GenerateClassContext =  ExtensionRegistry.get(GenerateClassContext)
	val transient extension RuleFactory =  ExtensionRegistry.get(RuleFactory)
	val transient extension MessageCollector = ExtensionRegistry.get(MessageCollector)
	
	def TypeMirror resolveTypeFromAnnotationValues(
		AnnotationMirror metaAnnotation,
		String typeAvName,
		String typeArgsAvName
	) {
		createTypeIfNecessary(
			resolveTypeFromAnnotationValues( metaAnnotation, typeAvName),
			resolveTypesFromAnnotationValues(metaAnnotation, typeArgsAvName)
		)
	}
	
	def private TypeMirror createTypeIfNecessary(TypeMirror type, List<? extends TypeMirror> typeArgs) {
		if (type == null || typeArgs.nullOrEmpty || !(type instanceof DeclaredType)) {
			type
		} else {
			getDeclaredType(type.asElement, typeArgs)
		}
	}

	def TypeMirror resolveTypeFromAnnotationValues(AnnotationMirror metaAnnotation, String typeAvName) { 

		val selector = metaAnnotation.value(typeAvName, TypeMirror)
		selector.resolveType

	}

	def List<? extends TypeMirror> resolveTypesFromAnnotationValues(AnnotationMirror metaAnnotation, String typeArgsAvName)  {

		val selectors =  metaAnnotation.value(typeArgsAvName, typeof(TypeMirror[]))
		selectors.map(s|s.resolveType)

	}
	
	def TypeMirror resolveType(TypeMirror selector) {
		resolveType(selector, true)
	}

	def dispatch TypeMirror resolveType(ArrayType selector, boolean required) {
		new GenArrayType(selector.componentType.resolveType(required))
	}
	
	def dispatch TypeMirror resolveType(DeclaredType selector, boolean required) {
		val typeFunctionResult = resolveTypeFunctionIfNecessary(selector)
		
		if(typeFunctionResult instanceof DeclaredType)  typeFunctionResult.resolveType_(required) else typeFunctionResult?.resolveType(required)
	}
	
	def dispatch TypeMirror resolveType(TypeMirror selector, boolean required) {
		selector
	}
	
	
	def private TypeMirror resolveType_(DeclaredType selector, boolean required) {

		
		try {			
			var type = selector
			
			//Always try to resolve error type if the type is required
			type = if(type instanceof ErrorType && required) type.asTypeElement.asType as DeclaredType else type
			
			//TODO: Wird das hier wirklich noch benötigt oder ist das redundant zu anderen Mechanismen (tenfe)?
			if (type != null && required) {
				currentAnnotatedClass.registerTypeDependencyForAnnotatedClass(type)
			}
			
			
			if(type == null) {
				type
			} else {
				//If there are type arguments, map them as well
				if(selector.typeArguments.nullOrEmpty){
					type
				} else {
					getDeclaredType(type.asElement as TypeElement, selector.typeArguments.map[
						resolveType(required)
					])				
				}	
			}
		} catch (TypeElementNotFoundException tenfe) {
			throw tenfe 
		} catch (Exception e) {
			reportRuleError(e)
			throw e;
		}

	}
	
	/**
	 * Checks it the type refers to a function. If so, the function is called and the resulting type mirror is returned.
	 */
	def private TypeMirror resolveTypeFunctionIfNecessary(DeclaredType type) {

			if (!(type instanceof ErrorType)) {
				//zusätzlicher Aufruf von getTypeElement wegen Bug in UnresolvedAnnotationBinding.getElementValuePairs(): Arrays mit UnresolvedTypeBindings werden nicht resolved.
				//TODO: Ist das schon in ElementsExtensions geregelt?
				var TypeElement te = type.asTypeElement
				if(!(type instanceof GenDeclaredType)){
					te =  getTypeElement(te.qualifiedName)		
					if(te==null){
						throw new TypeElementNotFoundException(te.qualifiedName.toString)
					}		
				}
		
				//if it is a function, call it and return the resulting type
				val function = createFunctionRule(te);
				
				if(function!=null){
					
					val result = function.apply
					if(result == null || result instanceof TypeMirror){
						return result as TypeMirror
					} else {
						reportRuleError('''«te.qualifiedName» cannot be used as type since it's result is not a TypeMirror but «result».''')
					}
					
				}
			}
		
		
		
		type
	}

}
