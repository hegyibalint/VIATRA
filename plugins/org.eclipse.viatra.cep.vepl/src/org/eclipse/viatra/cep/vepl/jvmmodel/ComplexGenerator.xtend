/*******************************************************************************
 * Copyright (c) 2004-2014, Istvan David, Istvan Rath and Daniel Varro
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 * Istvan David - initial API and implementation
 *******************************************************************************/
package org.eclipse.viatra.cep.vepl.jvmmodel

import com.google.common.collect.Lists
import com.google.common.collect.Maps
import com.google.inject.Inject
import java.util.List
import java.util.Map
import java.util.Map.Entry
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.cep.core.api.events.ParameterizableEventInstance
import org.eclipse.viatra.cep.core.api.patterns.ParameterizableComplexEventPattern
import org.eclipse.viatra.cep.core.metamodels.events.Event
import org.eclipse.viatra.cep.core.metamodels.events.EventsFactory
import org.eclipse.viatra.cep.vepl.jvmmodel.expressiontree.AtomicExpressionTree
import org.eclipse.viatra.cep.vepl.jvmmodel.expressiontree.ExpressionTreeBuilder
import org.eclipse.viatra.cep.vepl.jvmmodel.expressiontree.Leaf
import org.eclipse.viatra.cep.vepl.jvmmodel.expressiontree.Node
import org.eclipse.viatra.cep.vepl.vepl.AndOperator
import org.eclipse.viatra.cep.vepl.vepl.Atom
import org.eclipse.viatra.cep.vepl.vepl.ComplexEventExpression
import org.eclipse.viatra.cep.vepl.vepl.ComplexEventOperator
import org.eclipse.viatra.cep.vepl.vepl.ComplexEventPattern
import org.eclipse.viatra.cep.vepl.vepl.EventPattern
import org.eclipse.viatra.cep.vepl.vepl.FollowsOperator
import org.eclipse.viatra.cep.vepl.vepl.NegOperator
import org.eclipse.viatra.cep.vepl.vepl.OrOperator
import org.eclipse.viatra.cep.vepl.vepl.PatternCallParameter
import org.eclipse.viatra.cep.vepl.vepl.UntilOperator
import org.eclipse.xtext.common.types.JvmMember
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.common.types.TypesFactory
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.xbase.compiler.output.ITreeAppendable
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder

class ComplexGenerator {
	@Inject extension JvmTypesBuilder jvmTypesBuilder
	@Inject extension Utils
	@Inject extension NamingProvider
	@Inject AnonymousPatternManager anonManager = AnonymousPatternManager.instance
	@Inject ExpressionTreeBuilder expressionTreeBuilder = ExpressionTreeBuilder.instance

	def public generateComplexEventPatterns(List<ComplexEventPattern> patterns, IJvmDeclaredTypeAcceptor acceptor) {
		anonManager.flush
		for (pattern : patterns) {
			pattern.generateComplexEventPattern(acceptor)
		}
	}

	def public generateComplexEventPattern(ComplexEventPattern pattern, IJvmDeclaredTypeAcceptor acceptor) {
		if (pattern.complexEventExpression == null) {
			return
		}

		val expression = pattern.complexEventExpression;

		// TODO this case should be investigated as well
		if (expression instanceof Atom) {
			return
		}

		val expressionTree = expressionTreeBuilder.buildExpressionTree(pattern.complexEventExpression)

		if (expressionTree instanceof AtomicExpressionTree) {
			generateAtomicComplexEventPattern();
		}

		//		var patternGroups = disassembler.decomposeComplexPattern(pattern.complexEventExpression).entries.toList
		generateComplexEventPattern(pattern, expressionTree.root, pattern.patternFqn, acceptor)
	}

	def isRoot(Node node) {
		return node.parentNode == null
	}

	def public QualifiedName generateComplexEventPattern(
		ComplexEventPattern pattern,
		Node node,
		QualifiedName className,
		IJvmDeclaredTypeAcceptor acceptor
	) {
		var List<QualifiedName> compositionEvents = Lists::newArrayList

		for (child : node.children) {
			if (child instanceof Node) {
				val QualifiedName referredAnonymousPattern = generateComplexEventPattern(pattern, (child as Node),
					getAnonymousName(pattern, anonManager.nextIndex), acceptor);
				compositionEvents.add(referredAnonymousPattern)
			} else {
				compositionEvents.add(((child as Leaf).expression as Atom).patternCall.eventPattern.patternFqn)
			}
		}

		val QualifiedName currentClassName = if (node.root) {
				pattern.patternFqn
			} else {
				getAnonymousName(pattern, anonManager.nextIndex)
			}

		val ComplexPatternType patternType = if (node.root) {
				ComplexPatternType::NORMAL
			} else {
				ComplexPatternType::ANONYMOUS
			}

		pattern.generateComplexEventPattern(node, currentClassName, compositionEvents, acceptor, patternType)

		return currentClassName
	}

	def generateComplexEventPattern(ComplexEventPattern pattern, Node node, QualifiedName className,
		List<QualifiedName> compositionPatterns, IJvmDeclaredTypeAcceptor acceptor,
		ComplexPatternType complexPatternType) {
		acceptor.accept(pattern.toClass(className)).initializeLater [
			superTypes += pattern.newTypeRef(ParameterizableComplexEventPattern)
			members += pattern.toConstructor [
				body = [
					append(
						'''
							super();
						'''
					)
					append('''setOperator(''').append('''«referClass(it, pattern, EventsFactory)».eINSTANCE''').
						append('''.«node.operator.factoryMethod»''').append(
							''');
								''')
					it.append(
						'''
							
							// composition events
						''')
					for (p : compositionPatterns) {
						it.append('''getCompositionEvents().add(new ''').append('''«referClass(p, pattern)»''').
							append(
								'''());
									''')
					}
					it.append(
						'''
						setId("«className.toLowerCase»");''')
				]
			]
			if (complexPatternType.normal) {
				members += (pattern as ComplexEventPattern).parameterBindingDispatcher
				members += (pattern as ComplexEventPattern).simpleBindingMethod
			}
		]
		if (complexPatternType.normal) {
			FactoryManager.instance.add(className)
		} else if (complexPatternType.anonymous) {
			anonManager.add(className.toString)
			return className
		}
	}

	def generateAtomicComplexEventPattern() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")

	// TODO:implement
	}

	def public generateComplexEventPattern_old(
		ComplexEventPattern pattern,
		QualifiedName className,
		Entry<ComplexEventOperator, List<EventPattern>> patternGroup,
		QualifiedName anonymousPatternFqn,
		IJvmDeclaredTypeAcceptor acceptor,
		ComplexPatternType complexPatternType
	) {
		acceptor.accept(pattern.toClass(className)).initializeLater [
			superTypes += pattern.newTypeRef(ParameterizableComplexEventPattern)
			members += pattern.toConstructor [
				body = [
					append(
						'''
							super();
						'''
					)
					append('''setOperator(''').append('''«referClass(it, pattern, EventsFactory)».eINSTANCE''').
						append('''.«patternGroup.key.factoryMethod»''').append(
							''');
								''')
					it.append(
						'''
							
							// composition events
						''')
					if (anonymousPatternFqn != null) {
						it.append('''getCompositionEvents().add(new ''').append(
							'''«referClass(anonymousPatternFqn, pattern)»''').append(
							'''());
								''')
					}
					for (p : patternGroup.value) {
						it.append('''getCompositionEvents().add(new ''').append(
							'''«referClass(p.patternFqn, pattern)»''').append(
							'''());
								''')
					}
					it.append(
						'''
						setId("«className.toLowerCase»");''')
				]
			]
			if (complexPatternType.normal) {
				members += (pattern as ComplexEventPattern).parameterBindingDispatcher
				members += (pattern as ComplexEventPattern).simpleBindingMethod
			}
		]
		if (complexPatternType.normal) {
			FactoryManager.instance.add(className)
		} else if (complexPatternType.anonymous) {
			anonManager.add(className.toString)
			return className
		}
	}

	def boolean isNormal(ComplexPatternType complexPatternType) {
		return complexPatternType.equals(ComplexPatternType::NORMAL)
	}

	def boolean isAnonymous(ComplexPatternType complexPatternType) {
		return complexPatternType.equals(ComplexPatternType::ANONYMOUS)
	}

	def dispatch getFactoryMethod(FollowsOperator operator) {
		return "createFOLLOWS()"
	}

	def dispatch getFactoryMethod(OrOperator operator) {
		return "createOR()"
	}

	def dispatch getFactoryMethod(AndOperator operator) {
		return "createAND()"
	}

	def dispatch getFactoryMethod(UntilOperator operator) {
		return "createUNTIL()"
	}

	def dispatch getFactoryMethod(NegOperator operator) {
		return "createNEG()"
	}

	//	def unwrapExpression(ComplexEventExpression expression) {
	//		switch (expression) {
	//			PlainExpression:
	//				return expression
	//			AugmentedExpression: {
	//				return expression.expression
	//			}
	//		}
	//	}
	def Iterable<? extends JvmMember> getParameterBindingDispatcher(ComplexEventPattern pattern) {
		val method = TypesFactory.eINSTANCE.createJvmOperation
		method.simpleName = "evaluateParameterBindigs"
		method.setVisibility(JvmVisibility.PUBLIC)
		method.returnType = pattern.newTypeRef("boolean")
		method.parameters.add(method.toParameter("event", pattern.newTypeRef(Event)))
		method.setBody [
			append(
				'''
				if(event instanceof ''').append('''«referClass(it, method, ParameterizableEventInstance)»''').append(
				'''){
					''').append(
				'''
						return evaluateParameterBindigs((ParameterizableEventInstance) event);
					}
				''').append(
				'''
				return true;''')
		]

		method.addOverrideAnnotation(pattern)
		return Lists.newArrayList(method)
	}

	def Iterable<? extends JvmMember> getSimpleBindingMethod(ComplexEventPattern pattern) {
		val method = TypesFactory.eINSTANCE.createJvmOperation
		method.simpleName = "evaluateParameterBindigs"
		method.setVisibility(JvmVisibility.PUBLIC)
		method.returnType = pattern.newTypeRef("boolean")
		method.parameters.add(method.toParameter("event", pattern.newTypeRef(ParameterizableEventInstance)))
		val expression = pattern.complexEventExpression
		method.setBody [
			append('''«referClass(it, pattern, Map, pattern.newTypeRef("String"), pattern.newTypeRef("Object"))»''').
				append(''' params = ''').append('''«referClass(it, pattern, Maps)»''')
			append(
				'''.newHashMap();
					''')
			//			getParameterMapping(expression.unwrapCompositionEventsWithParameterList, method).append(
			//				'''
			//				return true;''')
			it.getParameterMapping(expression, method)
			//			it.getParameterMapping(expression.headExpressionAtom, method, "if")
			//			for (expressionAtom : expression.tailExpressionAtoms) {
			//				it.getParameterMapping(expressionAtom.expressionAtom, method, "else if")
			//			}
			append(
				'''return evaluateParamBinding(params, event);
					''')
		]

		return Lists.newArrayList(method)
	}

	var firstCondition = true

	def getCondition() {
		if (firstCondition) '''if''' else '''else if'''
	}

	//FIXME the params.put("«param.name»", value«i»); should look for the appropriate parameter position!
	def getParameterMapping(ITreeAppendable appendable, ComplexEventExpression expression, EObject ctx) {
		if (expression.left instanceof Atom) {
			val atom = expression.left as Atom
			if (atom.patternCall.parameterList != null && !atom.patternCall.parameterList.parameters.empty) {
				appendable.append(
					'''
					«condition» (event instanceof ''').append(
					'''«appendable.referClass(atom.patternCall.eventPattern.classFqn, ctx)»''').append(
					'''){
						''')

				var i = 0
				for (param : atom.patternCall.parameterList.parameters.filter[p|!p.ignorable]) {
					appendable.append('''	Object value«i» = ((''').append(
						'''«appendable.referClass(atom.patternCall.eventPattern.classFqn, ctx)»''').append(
						''') event).getParameter(«i»);
							''')
					appendable.append(
						'''	params.put("«param.name»", value«i»);
							''')
					i = i + 1
				}
				appendable.append(
					'''}
						''')
			}
		} else {
			appendable.getParameterMapping(expression.left, ctx)
		}
	}

	//FIXME the params.put("«param.name»", value«i»); should look for the appropriate parameter position!
	//	def getParameterMapping(ITreeAppendable appendable, ComplexExpressionAtom expressionAtom, EObject ctx,
	//		String condition) {
	//		if (expressionAtom.patternCall.parameterList != null &&
	//			!expressionAtom.patternCall.parameterList.parameters.empty) {
	//			appendable.append(
	//				'''
	//				«condition» (event instanceof ''').append(
	//				'''«appendable.referClass(expressionAtom.patternCall.eventPattern.classFqn, ctx)»''').append(
	//				'''){
	//					''')
	//
	//			var i = 0
	//			for (param : expressionAtom.patternCall.parameterList.parameters.filter[p|!p.ignorable]) {
	//				appendable.append('''	Object value«i» = ((''').append(
	//					'''«appendable.referClass(expressionAtom.patternCall.eventPattern.classFqn, ctx)»''').append(
	//					''') event).getParameter(«i»);
	//						''')
	//				appendable.append(
	//					'''	params.put("«param.name»", value«i»);
	//						''')
	//				i = i + 1
	//			}
	//			appendable.append(
	//				'''}
	//					''')
	//		}
	//	}
	def isIgnorable(PatternCallParameter parameter) {
		if (parameter.name.startsWith("_")) {
			return true
		}
		return false
	}
}
