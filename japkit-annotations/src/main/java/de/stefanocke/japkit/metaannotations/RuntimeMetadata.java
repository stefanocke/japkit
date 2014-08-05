package de.stefanocke.japkit.metaannotations;

import static javax.lang.model.element.ElementKind.CONSTRUCTOR;
import static javax.lang.model.element.ElementKind.METHOD;
import de.stefanocke.japkit.metaannotations.RuntimeMetadata.Element;
import de.stefanocke.japkit.metaannotations.RuntimeMetadata.List;

@Var(name="srcClass", triggerAV="srcClass", setInShadowAnnotation=true, expr="#{currentAnnotatedClass.asType()}")
@GenerateClass(nameSuffixToAppend=RuntimeMetadata.CLASS_SUFFIX, annotationMappings={
	@AnnotationMapping(id="elementMetadata", targetAnnotation=Element.class, 
			valueMappings={
				@AVMapping(name="id", expr="#{elements.uniqueName(src)}"), //TODO: uniqueId
				@AVMapping(name="comment", expr="#{elements.getDocComment(src)}"),
				@AVMapping(activation=@Matcher(kind={METHOD, CONSTRUCTOR}), name="paramNames", expr="#{src.parameters}")
		}),
	@AnnotationMapping(targetAnnotation=List.class, mode=AnnotationMappingMode.MERGE, 
		valueMappings=@AVMapping(name = "value", expr="#{elements.elementAndAllEnclosedElements(src)}", mode=AVMappingMode.JOIN_LIST, annotationMappingId="elementMetadata"))
})

public @interface RuntimeMetadata {
	public static final String CLASS_SUFFIX = "_RuntimeMetadata";
	
	boolean shadow() default false;
	
	Class<?>[] srcClass() default {};
	
	@interface Element {

		String id();
		String comment() default "";
		String[] paramNames() default {};
		
		
	}
	
	@interface List{
		Element[] value();
	}
}
