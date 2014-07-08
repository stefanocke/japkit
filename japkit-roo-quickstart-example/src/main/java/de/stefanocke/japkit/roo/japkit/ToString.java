package de.stefanocke.japkit.roo.japkit;

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import de.stefanocke.japkit.metaannotations.Case;
import de.stefanocke.japkit.metaannotations.Constructor;
import de.stefanocke.japkit.metaannotations.InnerClass;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.TypeCategory;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.metaannotations.Method;
import de.stefanocke.japkit.metaannotations.Properties;
import de.stefanocke.japkit.metaannotations.Template;
import de.stefanocke.japkit.metaannotations.classselectors.GeneratedClass;

@Template(vars = @Var(name = "toStringProperties", propertyFilter = @Properties(sourceClass = GeneratedClass.class)))
public abstract class ToString {
	@Method(imports = { ToStringBuilder.class, ToStringStyle.class },
			
			bodyIterator="#{toStringProperties}",
			//bodyIteratorVar="p"
			bodyBeforeExpr = "return new ToStringBuilder(this, ToStringStyle.SHORT_PREFIX_STYLE).\n",
			
			bodySwitch={
				//Only summary for collections
				@Case(matcher=@Matcher(srcTypeCategory=TypeCategory.COLLECTION), 
						expr = "append(\"#{element.simpleName}\", #{element.getter.simpleName}(), false).\n"),
			},
			bodyExpr = "append(\"#{element.simpleName}\", #{element.getter.simpleName}()).\n",
			bodyAfterExpr = "toString();\n",
			bodyEmptyExpr = "return super.toString();" 
			)
	public abstract String toString();
	
//	@Constructor(bodyExpr="//Some ctor code")
//	public ToString (){};
	
	//TODO: Take name from class if no nameExpr is given...  
	//TODO: Consider the inner class as a template for them members of the inner class to be generated.
	//TODO: rule src element for name expression should not always be the annotated class.
//	@InnerClass(iterator="#{toStringProperties}", nameExpr="#{parent.element.simpleName.toFirstUpper}InnerClassTest")
//	static class InnerClassTest{
//		@Method
//		void foo(){}
//	}
}
