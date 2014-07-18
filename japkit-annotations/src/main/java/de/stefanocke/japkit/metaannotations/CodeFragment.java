package de.stefanocke.japkit.metaannotations;

import javax.lang.model.element.Element;
import javax.lang.model.element.Modifier;

import de.stefanocke.japkit.metaannotations.classselectors.None;

/**
 * 
 * @author stefan
 * 
 */
public @interface CodeFragment {
	

	

	/**
	 *
	 * <p>
	 * In case of multiple matchers, at least one must match to activate the rule.
	 * 
	 * @return
	 */
	Matcher[] activation() default {};

	

	/**
	 * Classes to imported for the code. Allows to use short class names
	 * in the body expr. The imports are only added if they don't conflict with
	 * others. Otherwise, it's an error.
	 * 
	 * @return
	 */
	Class<?>[] imports() default {};

	/**
	 * If the body shall contain some repetitive code, this expression can be
	 * used. It determines how often to repeat bodyExpr. The iteration variable
	 * is provided as "element" on the value stack.
	 * <p>
	 * A typical example is to iterate over the properties of the class, to
	 * generate methods like toString or equals / hashcode.
	 * 
	 * 
	 * @return
	 */
	String iterator() default "";

	/**
	 * 
	 * @return the language of the body iterator expression. Default is Java EL.
	 */
	String iteratorLang() default "";

	/**
	 * 
	 * @return an expression to generate the body. The root property "element"
	 *         refers to the generated method or, if a bodyIterator is used, the current iterator element.
	 */
	String expr() default "";
	
	
	/**
	 * If there is at least one of the given cases, where all matcher match, the according expression is use instead of expr.
	 * If no case matches, the default is expr.
	 * 
	 * @return
	 */
	Case[] cases() default{};
	
	
	/**
	 * 
	 * @return if bodyIterator is set, this code is inserted between each
	 *         iteration of bodyExpr.
	 */
	String separator() default "";

	/**
	 * 
	 * @return an expression for the code to be generated before the repetitive
	 *         bodyExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String beforeExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated after the repetitive
	 *         bodyExpr. Only rendered, if the iterator expression is set and
	 *         does not result in an empty iterator.
	 */
	String afterExpr() default "";

	/**
	 * 
	 * @return an expression for the code to be generated if the iterator
	 *         expression is set but does result in an empty iterator.
	 */
	String emptyExpr() default "";

	/**
	 * 
	 * @return the language of the body expression. Default is Java EL.
	 */
	String lang() default "";

}