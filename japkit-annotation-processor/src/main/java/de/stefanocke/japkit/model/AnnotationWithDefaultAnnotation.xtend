package de.stefanocke.japkit.model

import java.util.HashMap
import javax.lang.model.element.AnnotationMirror
import org.eclipse.xtend.lib.Data

@Data
class AnnotationWithDefaultAnnotation implements AnnotationMirror{
	AnnotationMirror annotation
	AnnotationMirror defaultAnnotation
	
	override getAnnotationType() {
		annotation.annotationType
	}
	
	override getElementValues() {
		val result = new HashMap(defaultAnnotation.elementValues)
		result.putAll(annotation.elementValues)
		result
	}
	
	def static createIfNecessary(AnnotationMirror annotation, AnnotationMirror defaultAnnotation){
		if(annotation!=null && defaultAnnotation!=null) new AnnotationWithDefaultAnnotation(annotation, defaultAnnotation)
			else annotation ?: defaultAnnotation
		
	}
	
}