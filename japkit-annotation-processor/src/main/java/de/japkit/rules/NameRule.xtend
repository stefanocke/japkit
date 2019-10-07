package de.japkit.rules

import de.japkit.el.ELSupport
import de.japkit.services.ElementsExtensions
import de.japkit.services.ExtensionRegistry
import de.japkit.services.ProcessingException
import java.util.regex.Pattern
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import org.eclipse.xtend.lib.annotations.Data
import de.japkit.services.RuleException

/**
 * A NameRule describes how to derive the name of the target element from the source element.
 * This rule is only used at the "top-level", that is, for the generated classes and resources.
 * For members etc, the nameExprRule from RuleUtils is used instead.
 * (TODO: can this be harmonized without breaking something?)
 * 
 * The rule supports:
 * <ul>
 * <li>creating the name by RegEx replacement of the source name
 * <li>creating the name by evaluating an expression
 * </ul>
 */
@Data
class NameRule extends AbstractRule{
	Pattern regEx
	String regExReplace
	String expr
	String lang
	
	String avPrefix

	val transient extension ElementsExtensions = ExtensionRegistry.get(ElementsExtensions)
	val transient extension ELSupport = ExtensionRegistry.get(ELSupport)
	
	new(AnnotationMirror metaAnnotation, String avPrefix){
		super(metaAnnotation, null)
		this.avPrefix = if(avPrefix === null) "name" else avPrefix
		regEx = metaAnnotation.value('''«this.avPrefix»RegEx''', Pattern)
		regExReplace = metaAnnotation.value('''«this.avPrefix»RegExReplace''', String)		
		expr =  metaAnnotation.value('''«this.avPrefix»Expr''', String)		
		lang =  metaAnnotation.value('''«this.avPrefix»Lang''', String)		
	}
	
	def isEmpty(){
		regEx === null && expr === null
	}
		
	def String getName(CharSequence orgName){
		inRule[
			if(regEx !== null){
			
				val matcher = regEx.matcher(orgName)
				
				if(!matcher.matches){
					throw new RuleException('''Naming rule violated: Name "«orgName»" must match pattern "«regEx.pattern»"''','''«this.avPrefix»RegEx''')
				}
				try{
					val name =  matcher.replaceFirst(regExReplace)	
					if(name.empty){
						throw new RuleException('''Naming rule violated: Name "«orgName»" must not be empty after replacing with "«regExReplace»"''', '''«this.avPrefix»RegEx''')
					}
					return name
				} catch (RuntimeException e){
					throw new RuleException('''Exception when replacing RegEx "«regEx.pattern»" with "«regExReplace»": «e.message»''', '''«this.avPrefix»RegEx''')
				}
			
			} else if(!expr.nullOrEmpty) {
				handleException(null, '''«this.avPrefix»Expr''')[
					eval(expr, lang, String)
				]
			} else {
				orgName.toString
			}
		]
	}
}