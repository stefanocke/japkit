package de.japkit.test.classname;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Target;

import de.japkit.metaannotations.Trigger;

/**
 * The trigger annotation for the example. Refers to the template describing the
 * class to be generated.
 */
@Documented
@Trigger(template = ClassNameSuffixTemplate.class)
@Target(ElementType.TYPE)
public @interface ClassNameSuffixTrigger {
	/**
	 * All trigger annotations in japkit must have this annotation value. When
	 * generating a class, the trigger annotation is copied to the generated
	 * class and shadow is set to false to mark it as a copy.
	 * 
	 * @return true means, it is a copy of the original annotation.
	 */
	boolean shadow() default false;
}