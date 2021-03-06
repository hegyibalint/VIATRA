package org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex.anonymous;

import org.eclipse.viatra.cep.core.api.patterns.ParameterizableComplexEventPattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.Fall_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.Far_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.Left_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.Near_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.Rise_Pattern;
import org.eclipse.viatra.cep.core.metamodels.events.EventsFactory;

@SuppressWarnings("all")
public class _AnonymousPattern_37 extends ParameterizableComplexEventPattern {
  public _AnonymousPattern_37() {
    super();
    setOperator(EventsFactory.eINSTANCE.createOR());
    
    // contained event patterns
    addEventPatternRefrence(new Left_Pattern(), 1);
    addEventPatternRefrence(new Rise_Pattern(), 1);
    addEventPatternRefrence(new Fall_Pattern(), 1);
    addEventPatternRefrence(new Near_Pattern(), 1);
    addEventPatternRefrence(new Far_Pattern(), 1);
    setId("org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex.anonymous._anonymouspattern_37");
  }
}
