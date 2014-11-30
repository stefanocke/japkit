package de.stefanocke.japkit.model

import de.stefanocke.japkit.activeannotations.FieldsFromInterface
import javax.lang.model.element.VariableElement

import static javax.lang.model.element.ElementKind.*

@FieldsFromInterface
class GenEnumConstant extends GenVariableElement implements VariableElement{
	public static val kind = ENUM_CONSTANT		
}