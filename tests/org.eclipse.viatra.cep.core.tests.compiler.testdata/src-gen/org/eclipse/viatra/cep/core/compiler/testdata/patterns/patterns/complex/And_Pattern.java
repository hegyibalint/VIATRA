package org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex;

import org.eclipse.viatra.cep.core.api.patterns.ParameterizableComplexEventPattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.A_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.B_Pattern;
import org.eclipse.viatra.cep.core.metamodels.events.EventsFactory;

@SuppressWarnings("all")
public class And_Pattern extends ParameterizableComplexEventPattern {
  public And_Pattern() {
    super();
    setOperator(EventsFactory.eINSTANCE.createAND());
    
    // contained event patterns
    addEventPatternRefrence(new A_Pattern(), 1);
    addEventPatternRefrence(new B_Pattern(), 1);
    setId("org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex.and_pattern");
  }
}
