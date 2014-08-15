package de.stefanocke.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.Annotation;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.classselectors.AnnotatedClass;

@Clazz(nameSuffixToRemove = "ViewModelDef", nameSuffixToAppend = "ViewModel", modifier= Modifier.ABSTRACT)
@Properties(sourceClass = FormBackingObject.class, overrides = AnnotatedClass.class, setter = {},
		annotations = @Annotation(copyAnnotationsFromPackages = "*"))
public @interface ViewModel {
	boolean shadow() default false;

	Class<?> formBackingObject();
}
