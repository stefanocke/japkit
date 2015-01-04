package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.japkit.Layers;

@Trigger(layer=Layers.WEB_APP, libraries=WebScaffoldLibrary.class, vars={
		@Var(name = "controllers", ifEmpty=true, expr="#{findAllControllers()}")})
@ResourceTemplate.List({
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "application.jspx", pathExpr = "i18n",
				nameExpr = "application.properties", location = ResourceLocation.WEBINF),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "menu.jspx", pathExpr = "views",
				location = ResourceLocation.WEBINF) })
@Clazz(templates=@TemplateCall(JapkitWebApplicationTemplate.class))
public @interface JapkitWebApplication {
	boolean shadow() default false;

	Class<?>[] controllers() default {};
}
