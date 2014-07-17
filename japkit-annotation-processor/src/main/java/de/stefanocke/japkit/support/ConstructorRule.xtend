package de.stefanocke.japkit.support

import de.stefanocke.japkit.gen.GenConstructor
import javax.lang.model.element.AnnotationMirror
import javax.lang.model.element.Element
import javax.lang.model.element.ExecutableElement

class ConstructorRule extends ExecutableElementRule {

	new(AnnotationMirror metaAnnotation, ExecutableElement template) {
		super(metaAnnotation, template)
	}

	protected override createMember(Element ruleSrcElement) {
		val ctor = createMemberAndSetCommonAttributes(ruleSrcElement, [new GenConstructor])


		ctor.parameters = paramRules.apply(ruleSrcElement)

		val codeBody = bodyCodeRule.getAsCodeBody(ctor)
		if (codeBody != null) {
			ctor.body = codeBody
		}
		ctor
	}

	

}
