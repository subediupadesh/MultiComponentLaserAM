//* Created by Upadesh Subedi 30th June 2024
//* Equation source  for Bessel Heat Source: https://www.sciencedirect.com/science/article/pii/S2214785320405607 &  https://www.tandfonline.com/doi/epdf/10.1080/17452759.2024.2308513?needAccess=true & https://link.springer.com/article/10.1007/s11837-023-06363-8
//* Bessel with multiple ring: https://www.sciencedirect.com/science/article/pii/S0079672714000317
#pragma once
#include "ADMaterial.h"

class Function;
/*
Bessel Moving Heat Source 
*/
class LaserSource : public ADMaterial
{
    public:
        static InputParameters validParams();
        LaserSource(const InputParameters & parameters);

    protected:
        virtual void computeQpProperties() override;

        const MaterialProperty<Real> & _P;  // Power of the laser Source
        const Function & _laser_switch;   // Laser switch 1 for ON and 0 for OFF, as a function of simulation time
        Real _eta; // Efficiency
        Real _a0;  // Proportion of Source Power to the Middle Gaussian Beam
        Real _a1;  // Proportion of Source Power to the First Ring Beam
        Real _a2;  // Proportion of Source Power to the Second Ring Beam
        Real _a3;  // Proportion of Source Power to the Third Ring Beam
        Real _Ca; // Coefficient Constant Inside Exponential for Inner Gaussian Beam
        Real _Cb; // Coefficient Constant Inside Exponential for Outer Ring Beam
        const MaterialProperty<Real> & _rG;  // Gaussian Laser Beam Radius
        const MaterialProperty<Real> & _rR;  // First Ring Laser Beam Radius
        const MaterialProperty<Real> & _rT;  // First Ring Beam Half Thickness
        const MaterialProperty<Real> & _rR1; // First Ring Laser Beam Radius
        const MaterialProperty<Real> & _rT1; // First Ring Beam Half Thickness
        const MaterialProperty<Real> & _rR2; // Second Ring Laser Beam Radius
        const MaterialProperty<Real> & _rT2; // Second Ring Beam Half Thickness
        const MaterialProperty<Real> & _rR3; // Third Ring Laser Beam Radius
        const MaterialProperty<Real> & _rT3; // Third Ring Beam Half Thickness
        const MaterialProperty<Real> & _rz; // Laser Beam Spot Radius Depth, In 2D it is a unit constant
        Real _F; // Correction Factor
        Real _K; // Super Gaussian Order
        const MaterialProperty<Real> & _A; // Absorptivity of Material
        const Function & _function_x; // Path of HS x-coord
        const Function & _function_y; // Path of HS y-coord
        const Function & _function_z; // Path of HS z-coord // In 2-D value if 0
        ADMaterialProperty<Real> & _volumetric_heat; // Total volumetric heat 
        MooseEnum _beam_type; // Beam Type: 0 for Gaussian, 1 for Flat-Top, 2 for Ring, 3 for Bessel
};
