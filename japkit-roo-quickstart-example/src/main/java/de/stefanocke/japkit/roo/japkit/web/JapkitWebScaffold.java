package de.stefanocke.japkit.roo.japkit.web;

import javax.lang.model.element.Modifier;
import javax.lang.model.type.TypeMirror;

import org.springframework.data.jpa.repository.JpaRepository;

import de.stefanocke.japkit.annotations.RuntimeMetadata;
import de.stefanocke.japkit.metaannotations.Clazz;
import de.stefanocke.japkit.metaannotations.Matcher;
import de.stefanocke.japkit.metaannotations.ResourceLocation;
import de.stefanocke.japkit.metaannotations.ResourceTemplate;
import de.stefanocke.japkit.metaannotations.SingleValue;
import de.stefanocke.japkit.metaannotations.TemplateCall;
import de.stefanocke.japkit.metaannotations.Trigger;
import de.stefanocke.japkit.metaannotations.Var;
import de.stefanocke.japkit.roo.japkit.Layers;
import de.stefanocke.japkit.roo.japkit.application.ApplicationServiceLibrary;
import de.stefanocke.japkit.roo.japkit.domain.DomainLibrary;

@RuntimeMetadata
@Trigger(layer=Layers.CONTROLLERS, 
	libraries={DomainLibrary.class, ApplicationServiceLibrary.class, WebScaffoldLibrary.class},
	vars={
		@Var(name = "fbo", expr = "#{formBackingObject}"),
		@Var(name = "fboName", type = String.class, ifEmpty=true, expr = "#{fbo.simpleName.toString()}"),
		@Var(name = "fboPluralName", type = String.class, ifEmpty=true, expr = "#{fboName}s"),
		@Var(name = "path", type = String.class, ifEmpty=true, expr = "#{fboPluralName.toLowerCase()}"),
		@Var(name = "modelAttribute", type = String.class, ifEmpty=true, expr = "#{fboName.toFirstLower}"),
		
		// For making IDs in JSPs unique
		@Var(name = "fboFqnId", expr = "#{fbo.qualifiedName.toHtmlId()}"),	
		@Var(name = "fboShortId", expr = "#{fboName.toLowerCase()}"),

		@Var(name = "viewModel", expr="#{fbo.findViewModel()}"),
		
		// The properties to show
		@Var(name = "viewProperties", expr="#{(viewModel != null ? viewModel : fbo).viewableProperties()}"),
		@Var(name = "datetimeProperties", expr = "#{isDatetime.filter(viewProperties)}"),
		@Var(name = "enumProperties", expr = "#{isEnum.filter(viewProperties)}"),

		
		@Var(name = "explicitTableProperties", expr = "#{isTableColumn.filter(viewProperties)}"),
		@Var(name = "tableProperties", expr = "#{explicitTableProperties.isEmpty() ? viewProperties : explicitTableProperties}"),
		
		@Var(name = "entityProperties", expr = "#{isEntity.filter(viewProperties)}"),
		@Var(name = "relatedEntities", expr = "entityProperties.collect{it.singleValueType.asElement()}", lang="GroovyScript"),
				
		@Var(name = "repository", type = TypeMirror.class, ifEmpty = true, expr="#{fbo.findRepository()}"),		
		@Var(name = "applicationService", expr="#{fbo.findApplicationService()}"),

		@Var(name="createCommands", expr="#{applicationService.findCreateCommandMethods()}"),
		@Var(name="updateCommands", expr="#{applicationService.findUpdateCommandMethods()}"),
		@Var(name = "propertyNames", ifEmpty=true, expr="#{allPropertyNames(viewProperties)}")		

})
@Clazz(
		nameSuffixToRemove = "Def",
		nameSuffixToAppend = "",
		//superclassTypeArgs=FormBackingObject.class,
		
		modifiers = Modifier.PUBLIC,
		customBehaviorActivation=@Matcher(condition="#{triggerAnnotation.customBehavior}"),
		templates = {
				@TemplateCall(ControllerMembers.class),
				@TemplateCall(ControllerMembersJpaRepository.class) ,
				@TemplateCall(ControllerFormatterMembers.class)
				})
@ResourceTemplate.List({
		@ResourceTemplate(src="#{createCommands.get(0)}", srcVar="cmdMethod", 
				templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "create.jspx", location = ResourceLocation.WEBINF, 
				vars ={ @Var(name = "update", expr = "#{false}"), 
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="modelAttribute", expr="#{command.simpleName.toFirstLower}"),
					@Var(name = "viewProperties", expr="#{command.properties}"),
				}),
		@ResourceTemplate(src="#{createCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "command_i18n.jspx", pathExpr = "i18n/#{path}",
				nameExpr = "#{cmdMethod.simpleName}.properties", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="cmdName", expr="#{cmdMethod.simpleName}"),
					@Var(name = "cmdPropertyNames", expr="#{allPropertyNames(command.properties)}"),
				}),
		@ResourceTemplate(src="#{updateCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "createOrUpdate.jspx", pathExpr = "views/#{path}",
				nameExpr = "#{cmdMethod.simpleName.toFirstLower}.jspx", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name = "update", expr = "#{true}"),
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="modelAttribute", expr="#{command.simpleName.toFirstLower}"),
					@Var(name = "viewProperties", expr="#{command.properties}"),
				}),
		@ResourceTemplate(src="#{updateCommands}", srcVar="cmdMethod",
				templateLang = "GStringTemplate", templateName = "command_i18n.jspx", pathExpr = "i18n/#{path}",
				nameExpr = "#{cmdMethod.simpleName}.properties", location = ResourceLocation.WEBINF, 
				vars = {
					@Var(name="command", expr="#{cmdMethod.command()}"),
					@Var(name="cmdName", expr="#{cmdMethod.simpleName}"),
					@Var(name = "cmdPropertyNames", expr="#{allPropertyNames(command.properties)}"),
				}),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "show.jspx", location = ResourceLocation.WEBINF,
				pathExpr = "views/#{path}"),
		@ResourceTemplate(templateLang = "GStringTemplate", templateName = "list.jspx", location = ResourceLocation.WEBINF,
				pathExpr = "views/#{path}") })
public @interface JapkitWebScaffold {

	boolean shadow() default false;

	/**
	 * Every controller is responsible for a single form backing object. The
	 * form backing object defined here class will be exposed in a RESTful way.
	 */
	Class<?> formBackingObject();
	
	Class<?>[] viewModel() default {};

	/**
	 * All view-related artifacts for a specific controller are stored in a
	 * sub-directory under WEB-INF/views/<em>path</em>. The path parameter
	 * defines the name of this sub-directory or path. This path is also used to
	 * define the restful resource in the URL to which the controller is mapped.
	 * 
	 * @return The view path.
	 */
	String path() default "";

	boolean customBehavior() default false;

	/**
	 * 
	 * @return the name of the model attribute for the formBackingObject. By
	 *         default, the class name with first lower case.
	 */
	String modelAttribute() default "";

	@SuppressWarnings("rawtypes")
	@SingleValue
	Class<? extends JpaRepository>[] repository() default {};

	@SingleValue
	Class<?>[] applicationService() default {};
	/**
	 * 
	 * @return the unique id for the fbo class used in JSPs and i18n
	 */
	String fboFqnId() default "";

	String fboShortId() default "";

	String fboName() default "";

	String fboPluralName() default "";

	// For i18n. TODO: Reconsider
	String[] propertyNames() default {};
	
	
}
