//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#ifndef PHASEGLOBALCOMPOSITION_H
#define PHASEGLOBALCOMPOSITION_H

#include "AuxKernel.h"

// Forward Declarations
class PhaseGlobalComposition;


/**
 * Auxiliary kernel responsible for computing the Darcy velocity given
 * several fluid properties and the pressure gradient.
 */
class PhaseGlobalComposition : public AuxKernel
{
public:
  static InputParameters validParams();
  PhaseGlobalComposition(const InputParameters & parameters);

protected:
  /**
   * AuxKernels MUST override computeValue.  computeValue() is called on
   * every quadrature point.  For Nodal Auxiliary variables those quadrature
   * points coincide with the nodes.
   */
  virtual Real computeValue() override;

  /// Value of the coupled variable
  const VariableValue & _coupled_var;

  /// Number of switching functions (phases)
  const unsigned int _total_etas;

  /// Vector of material properties for switching functions
  std::vector<const MaterialProperty<Real> *> _prop_h;

};

#endif // PHASEGLOBALCOMPOSITION_H
