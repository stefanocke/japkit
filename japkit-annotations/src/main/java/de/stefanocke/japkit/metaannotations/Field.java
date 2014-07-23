package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Element;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * Anntoation to add a field to a generated class.
 * 
 * @author stefan
 * 
 */
@MemberGeneratorAnnotation
public @interface Field {
	/**
	 * When the annotated annotation wants to override annotation values of the
	 * Method annotation, it must use this prefix.
	 * 
	 * @return
	 */
	String _prefix() default "<field>";

	/**
	 * By default, only one field is generated by that annotation. To generate
	 * multiple similar fields you can set an EL expression here. It must be an
	 * {@link Iterable} over {@link Element}. For each of those elements, a
	 * field is generated. The element is also used as rule source element for
	 * all matchers and EL expressions in the following. (For example, this
	 * allows for a nameExpr that determines the name depending on that
	 * element.)
	 * 
	 * @return
	 */
	String iterator() default "";

	/**
	 * 
	 * @return the language of the iterator expression. Defaults to Java EL.
	 */
	String iteratorLang() default "";

	/**
	 * EL Variables within the scope of the field. The root property "element"
	 * refers to the enclosing class or to the current element of the iterator.
	 * 
	 * @return
	 */
	Var[] vars() default {};

	/**
	 * By default, this field annotation is active and will generate a field.
	 * To switch it on or of case by case, a Matcher can be used here. The
	 * element on which the matcher is applied is the enclosing class.
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the rule.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};

	/**
	 * 
	 * @return the name of the method. If not empty, nameExpr is ignored.
	 */
	String name() default "";

	/**
	 * For more complex cases: a Java EL expression to generate the name of the
	 * field. The root property "element" refers to the enclosing class.
	 * 
	 * @return
	 */
	String nameExpr() default "";

	/**
	 * 
	 * @return the language of the name expression. Defaults to Java EL.
	 */
	String nameLang() default "";

	/**
	 * 
	 * @return the type of the field.
	 */
	Class<?> type() default None.class;

	Class<?>[] typeArgs() default {};

	/**
	 * 
	 * @return the modifiers of the field
	 */
	Modifier[] modifiers() default {};

	/**
	 * How to map annotations of the source element (???) to the field
	 * <p>
	 * 
	 * @return the annotation mappings
	 */
	AnnotationMapping[] annotationMappings() default {};

	/**
	 * Classes to be imported for the initializer. Allows to use short class
	 * names in the expr. The imports are only added if they don't conflict with
	 * others. Otherwise, it's an error. TODO: Instead of an error , we could
	 * replace the short name in the body by the fqn.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * If the init expression shall contain some repetitive code, this
	 * expression can be used. It determines how often to repeat initExpr. The
	 * iteration variable is provided as "element" on the value stack.
	 * <p>
	 * A typical example is to initialize some array with the names of the
	 * properties of the class.
	 * 
	 * 
	 * @return
	 */
	String initIterator() default "";

	/**
	 * 
	 * @return the language of the init iterator expression. Default is Java EL.
	 */
	String initIteratorLang() default "";

	/**
	 * 
	 * @return if inityIterator is set, this code is inserted between each
	 *         iteration of initExpr.
	 */
	String initSeparator() default "";

	/**
	 * 
	 * @return an expression for the code to be generated before the repetitive
	 *         initExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initBeforeExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated after the repetitive
	 *         initExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String initAfterExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String initEmptyExpr() default "";

	/**
	 * 
	 * @return a Java EL expression to generate the initializer. The root
	 *         property "element" refers to the generated field.
	 */
	String initExpr() default "";
	
	/**
	 * If there is at least one of the given cases, where all matcher match, the according expression is use instead of initExpr.
	 * If no case matches, the default is initExpr.
	 * 
	 * @return
	 */
	Case[] initCases() default{};

	/**
	 * 
	 * @return the language of the init expression. Default is Java EL.
	 */
	String initLang() default "";

	/**
	 * The delegate methods to create. The delegate is the generated field.
	 * 
	 * @return
	 */
	DelegateMethods[] delegateMethods() default {};
	
	/**
	 * 
	 * @return true means to copy the JavaDoc comment from the rule source element 
	 */
	boolean commentFromSrc() default false;
	/**
	 * 
	 * @return an expression to create the JavaDoc comment
	 */
	String commentExpr() default "";
	
	/**
	 * 
	 * @return the expression language for commentExpr
	 */
	String commentLang() default "";
	
	/**
	 * 
	 * @return whether to generate a getter for the field
	 */
	boolean generateGetter() default false;
	
	Matcher[] getterActivation() default {};
	
	Modifier[] getterModifiers() default { Modifier.PUBLIC };

	AnnotationMapping[] getterAnnotationMappings() default {};
	
	/**
	 * Names of code fragments to surround the return expression.
	 */
	String[] getterSurroundReturnExprFragments() default {};
	
	/**
	 * 
	 * @return names of the fragments to surround the generated code body.
	 */
	String[] getterSurroundingFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] getterBeforeFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] getterAfterFragments() default{};
	
	
	/**
	 * 
	 * @return an expression to create the JavaDoc comment
	 */
	String getterCommentExpr() default "";
	
	/**
	 * 
	 * @return the expression language for commentExpr
	 */
	String getterCommentLang() default "";
	
	
	/**
	 * 
	 * @return whether to generate a setter for the field
	 */
	boolean generateSetter() default false;
	
	Matcher[] setterActivation() default {};
	
	Modifier[] setterModifiers() default { Modifier.PUBLIC };
	
	AnnotationMapping[] setterAnnotationMappings() default {};
	
	AnnotationMapping[] setterParamAnnotationMappings() default {};
	
	/**
	 * Names of code fragments to surround the assignment expression.
	 */
	String[] setterSurroundAssignmentExprFragments() default {};
	
	/**
	 * 
	 * @return names of the fragments to surround the generated code body.
	 */
	String[] setterSurroundingFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] setterBeforeFragments() default{};
	
	/**
	 * 
	 * @return names of the fragments to be inserted before the generated code body.
	 */
	String[] setterAfterFragments() default{};
	
	/**
	 * 
	 * @return an expression to create the JavaDoc comment
	 */
	String setterCommentExpr() default "";
	
	/**
	 * 
	 * @return the expression language for commentExpr
	 */
	String setterCommentLang() default "";
	

	@interface List {
		Field[] value();
	}
}
