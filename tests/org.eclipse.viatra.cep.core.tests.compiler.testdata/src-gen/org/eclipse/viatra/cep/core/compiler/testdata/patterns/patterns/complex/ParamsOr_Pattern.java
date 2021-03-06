package org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex;

import com.google.common.collect.Lists;
import org.eclipse.viatra.cep.core.api.patterns.ParameterizableComplexEventPattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.A_1_Pattern;
import org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.atomic.B_1_Pattern;
import org.eclipse.viatra.cep.core.metamodels.events.EventsFactory;

@SuppressWarnings("all")
public class ParamsOr_Pattern extends ParameterizableComplexEventPattern {
  public ParamsOr_Pattern() {
    super();
    setOperator(EventsFactory.eINSTANCE.createOR());
    
    // contained event patterns
    addEventPatternRefrence(new A_1_Pattern(), 1, Lists.newArrayList("param"));
    addEventPatternRefrence(new B_1_Pattern(), 1, Lists.newArrayList("param"));
    setId("org.eclipse.viatra.cep.core.compiler.testdata.patterns.patterns.complex.paramsor_pattern");
  }
}
