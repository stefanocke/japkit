package de.stefanocke.japkit.roo.japkit.web;

import de.stefanocke.japkit.metaannotations.classselectors.ClassSelector;
import de.stefanocke.japkit.metaannotations.classselectors.ClassSelectorKind;


@ClassSelector(kind = ClassSelectorKind.EXPR, expr = "#{relatedEntityRepository}")
public abstract class RelatedEntityRepository {
}