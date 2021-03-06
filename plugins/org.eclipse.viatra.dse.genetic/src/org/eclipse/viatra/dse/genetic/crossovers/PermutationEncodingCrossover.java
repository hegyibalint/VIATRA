/*******************************************************************************
 * Copyright (c) 2010-2014, Miklos Foldenyi, Andras Szabolcs Nagy, Abel Hegedus, Akos Horvath, Zoltan Ujhelyi and Daniel Varro
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * Contributors:
 *   Miklos Foldenyi - initial API and implementation
 *   Andras Szabolcs Nagy - initial API and implementation
 *******************************************************************************/
package org.eclipse.viatra.dse.genetic.crossovers;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Random;

import org.eclipse.viatra.dse.api.DSEException;
import org.eclipse.viatra.dse.api.DSETransformationRule;
import org.eclipse.viatra.dse.base.ThreadContext;
import org.eclipse.viatra.dse.designspace.api.ITransition;
import org.eclipse.viatra.dse.genetic.core.InstanceData;
import org.eclipse.viatra.dse.genetic.interfaces.ICrossoverTrajectories;

public class PermutationEncodingCrossover implements ICrossoverTrajectories {

    private Random random = new Random();

    @Override
    public Collection<InstanceData> crossover(List<InstanceData> parents, ThreadContext context) {
        // TODO question: is it bad, if the initial child already has those
        // rules from parent2?

        List<ITransition> parent1 = parents.get(0).trajectory;
        List<ITransition> parent2 = parents.get(1).trajectory;

        
        
        if (parent1.size() < 2 || parent2.size() < 2) {
            throw new DSEException("Cannot crossover with empty or one long parent trajectories");
        }

        int shorterSize = parent1.size() > parent2.size() ? parent2.size() : parent1.size();
        
        int index = random.nextInt(shorterSize - 1) + 1;

        List<ITransition> child1 = new ArrayList<ITransition>(parent1.subList(0, index));
        outerLoop: for (ITransition transition : parent2) {

            DSETransformationRule<?, ?> ruleToAdd = transition.getTransitionMetaData().rule;

            for (ITransition childTransition : child1) {
                DSETransformationRule<?, ?> childRule = childTransition.getTransitionMetaData().rule;
                if (ruleToAdd.equals(childRule)) {
                    continue outerLoop;
                }
            }

            child1.add(transition);
        }

        ArrayList<ITransition> child2 = new ArrayList<ITransition>(parent2.subList(0, index));
        outerLoop: for (ITransition transition : parent1) {
            
            DSETransformationRule<?, ?> ruleToAdd = transition.getTransitionMetaData().rule;
            
            for (ITransition childTransition : child2) {
                DSETransformationRule<?, ?> childRule = childTransition.getTransitionMetaData().rule;
                if (ruleToAdd.equals(childRule)) {
                    continue outerLoop;
                }
            }
            
            child2.add(transition);
        }

        return Arrays.asList(new InstanceData(child1), new InstanceData(child2));
    }

    @Override
    public int numberOfNeededParents() {
        return 2;
    }

    @Override
    public int numberOfCreatedChilds() {
        return 2;
    }

}
