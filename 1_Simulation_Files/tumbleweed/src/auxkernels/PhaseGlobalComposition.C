//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "PhaseGlobalComposition.h"

registerMooseObject("tumbleweedApp", PhaseGlobalComposition);

InputParameters
PhaseGlobalComposition::validParams()
{
  InputParameters params =  AuxKernel::validParams();
  params.addClassDescription("Computes the global composition weighted by the squared switching functions of multiple phases at each quadrature point.");

  // Add a required parameter for the number of switching functions
  params.addRequiredParam<unsigned int>("total_etas", "Total number of switching functions representing etas or phases");
  
  // Add a required coupled variable
  params.addRequiredCoupledVar("global_composition", "Coupled variable: global composition");

  // Add parameters for switching functions dynamically based on total_etas
  params.addRequiredParam<std::vector<MaterialPropertyName>>("h_names", "List of switching function names: h1, h2, ..., hn");

  return params;
}

PhaseGlobalComposition::PhaseGlobalComposition(const InputParameters & parameters)
  : AuxKernel(parameters),

    _coupled_var(coupledValue("global_composition")),
    _total_etas(getParam<unsigned int>("total_etas")),
    _prop_h(_total_etas)
{
    // Get the vector of switching function names
  const std::vector<MaterialPropertyName> & h_names = getParam<std::vector<MaterialPropertyName>>("h_names");

    // Validate that the number of h_names matches total_etas
  if (h_names.size() != _total_etas)
    paramError("h_names", "The number of h_names must equal total_etas (", _total_etas, ")");

  // Initialize the vector of material properties
  for (unsigned int i = 0; i < _total_etas; ++i)
    _prop_h[i] = &getMaterialProperty<Real>(h_names[i]);
}

Real
PhaseGlobalComposition::computeValue()
{
  Real sum_h_squared = 0.0;
  for (unsigned int i = 0; i < _total_etas; ++i)
    sum_h_squared += (*_prop_h[i])[_qp] * (*_prop_h[i])[_qp];

  return _coupled_var[_qp] * sum_h_squared;
}
