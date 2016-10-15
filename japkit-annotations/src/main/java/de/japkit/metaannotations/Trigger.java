package de.japkit.metaannotations;

import static java.lang.annotation.ElementType.ANNOTATION_TYPE;

import java.lang.annotation.Target;

/**
 * Marks an annotation type as trigger annotation.
 * 
 * 
 *  
 * @author stefan
 *
 */
@Target(value = ANNOTATION_TYPE)
public @interface Trigger {
	
	/**
	 * Libraries with functions to be made available for use in expressions.
	 */
	Class<?>[] libraries() default {};
	
	/**
	 * Annotations that shall be accessed by their simple names like this: typeElement.Entity
	 * 
	 * @return
	 */
	Class<? extends java.lang.annotation.Annotation>[] annotationImports() default {};
	
	/**
	 * Variables in the scope of the annotated class. 
	 * @return
	 */
	Var[] vars() default {};
	
	/**
	 * The layer of the trigger annotations. Code generation by trigger annotations in layer n may only depend on (classes generated by) 
	 * trigger annotations that have a layer less or equal n.
	 * <p>
	 * Primarily, this is a performance optimization for japkit. But it is also useful to enforce architectural constraints.
	 * (However, note that there might be differences between this layering and the layering and dependencies in the application.
	 * For example, a DTO might be generated from an Entity, so @DTO must be on a higher layer than @Entity. On the other hand, 
	 * the generated DTO usually will not have any dependencies on the entity.)
	 * 
	 * @return
	 */
	int layer() default 0;
	
	/**
	 * The Template for the top level class to be generated. The template must have the @Clazz annotation.
	 * @return
	 */
	Class<?>[] template() default {};
}
