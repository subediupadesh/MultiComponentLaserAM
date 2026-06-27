//* Created by Upadesh Subedi 30th June 2024
//* Equation source  for Bessel Heat Source: https://www.sciencedirect.com/science/article/pii/S2214785320405607 &  https://www.tandfonline.com/doi/epdf/10.1080/17452759.2024.2308513?needAccess=true &  https://link.springer.com/article/10.1007/s11837-023-06363-8
//* Bessel with multiple ring: https://www.sciencedirect.com/science/article/pii/S0079672714000317

#include "LaserSource.h"
#include "Function.h"

registerMooseObject("tumbleweedApp", LaserSource);

InputParameters
LaserSource::validParams()
{
    InputParameters params = ADMaterial::validParams();
    params.addClassDescription("Bessel Volumetric Moving Heat Source");

    MooseEnum beam_type("Gaussian=0 FlatTop=1 Ring=2 Bessel=3", "Gaussian");
    params.addParam<MooseEnum>("beam_type", beam_type, "Type of the laser beam source");
    params.addParam<MaterialPropertyName>("power", 1, "Power of the laser Source");
    params.addParam<FunctionName>("laser_switch", 1, "Laser switch 1 for ON and 0 for OFF, as a function of simulation time");
    params.addParam<Real>("efficiency", 1, "Process Efficiency");
    params.addParam<Real>("a0", 0.4, "Proportion of Source Power to the Middle Gaussian Beam");
    params.addParam<Real>("a1", 0.3, "Proportion of Source Power to the First Ring Beam");
    params.addParam<Real>("a2", 0.2, "Proportion of Source Power to the Second Ring Beam");
    params.addParam<Real>("a3", 0.1, "Proportion of Source Power to the Third Ring Beam");
    params.addParam<Real>("Ca", 2, "Coefficient Constant Outside Exponential");  //  Eq 2a: https://link.springer.com/article/10.1007/s11837-023-06363-8 & use rG = 2*sigma_G
    params.addParam<Real>("Cb", 2, "Coefficient Constant Inside Exponential");   //  rG = 2*sigma_G  # Eq 3: https://www.sciencedirect.com/science/article/pii/S0925838821002103
    params.addParam<MaterialPropertyName>("rG", 1, "Inner Gaussian Laser Beam Radius");
    params.addParam<MaterialPropertyName>("rR", 1, "Ring Beam Radius");
    params.addParam<MaterialPropertyName>("rT", 1, "Ring Beam Half Thickness");
    params.addParam<MaterialPropertyName>("rR1", 1, "First Ring Beam Radius");
    params.addParam<MaterialPropertyName>("rT1", 1, "First Ring Beam Half Thickness");
    params.addParam<MaterialPropertyName>("rR2", 1, "Second Ring Beam Radius");
    params.addParam<MaterialPropertyName>("rT2", 1, "Second Ring Beam Half Thickness");
    params.addParam<MaterialPropertyName>("rR3", 1, "Third Ring Beam Radius");
    params.addParam<MaterialPropertyName>("rT3", 1, "Third Ring Beam Half Thickness");
    params.addParam<MaterialPropertyName>("rz", 1, "Laser Beam Spot Radius Depth, In 2D it is a unit constant");
    params.addParam<Real>("factor", 1, "Correction Factor");
    params.addParam<Real>("SGOrder_K", 1, "Super Gaussian Order, if K=1, then it is pure Gaussian");
    params.addParam<MaterialPropertyName>("alpha", 1, "Material Heat Absorption Coefficient");
    params.addParam<FunctionName>("function_x", 0, "The x coordinate of the center of beam spot as a function of time for moving laser");
    params.addParam<FunctionName>("function_y", 0, "The y coordinate of the center of beam spot as a function of time for moving laser");
    params.addParam<FunctionName>("function_z", 0, "The z coordinate of the center of beam spot as a function of time for moving laser");
    return params;
}

LaserSource::LaserSource(const InputParameters & parameters)
: Material(parameters),
_beam_type(getParam<MooseEnum>("beam_type")),
_P(getMaterialProperty<Real>("power")),
_laser_switch(getFunction("laser_switch")),
_eta(getParam<Real>("efficiency")),
_a0(getParam<Real>("a0")),
_a1(getParam<Real>("a1")),
_a2(getParam<Real>("a2")),
_a3(getParam<Real>("a3")),
_Ca(getParam<Real>("Ca")),
_Cb(getParam<Real>("Cb")),
_rG(getMaterialProperty<Real>("rG")),
_rR(getMaterialProperty<Real>("rR")),
_rT(getMaterialProperty<Real>("rT")),
_rR1(getMaterialProperty<Real>("rR1")),
_rT1(getMaterialProperty<Real>("rT1")),
_rR2(getMaterialProperty<Real>("rR2")),
_rT2(getMaterialProperty<Real>("rT2")),
_rR3(getMaterialProperty<Real>("rR3")),
_rT3(getMaterialProperty<Real>("rT3")),
_rz(getMaterialProperty<Real>("rz")),
_F(getParam<Real>("factor")),
_K(getParam<Real>("SGOrder_K")),
_A(getMaterialProperty<Real>("alpha")),
_function_x(getFunction("function_x")),
_function_y(getFunction("function_y")),
_function_z(getFunction("function_z")),
_volumetric_heat(declareADProperty<Real>("volumetric_heat"))
{

}


void
LaserSource::computeQpProperties()
{
    const Real & x = _q_point[_qp](0);
    const Real & y = _q_point[_qp](1);
    const Real & z = _q_point[_qp](2);

    Real x_t = _function_x.value(_t);
    Real y_t = _function_y.value(_t);
    Real z_t = _function_z.value(_t);
    Real _SWITCH = _laser_switch.value(_t);

    switch (_beam_type)
    {
        case 0: // Gaussian

            if(_SWITCH==0){
                _volumetric_heat[_qp] = 0;
            }
            else{
                _volumetric_heat[_qp] = (
                                            ((_Ca*_P[_qp]*_eta*_A[_qp]*_F) / (libMesh::pi*std::pow(_rG[_qp], 2.0)*_rz[_qp]))*(std::exp(-_Cb* (((std::pow(x-x_t, 2.0)+std::pow(y-y_t, 2.0))/(std::pow(_rG[_qp], 2.0))) + ((std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))) )))
                                        );
            }
            break;
    
        case 1: // FlatTop
            if(_SWITCH==0){
                _volumetric_heat[_qp] = 0;
            }
            else{
                _volumetric_heat[_qp] = (
                                            ((std::pow(_Ca, 1/_K)*_K*_P[_qp]*_eta*_A[_qp]*_F) / (libMesh::pi*std::pow(_rG[_qp], 2.0)*_rz[_qp]*std::tgamma(1/_K)))*(std::exp(-_Cb*((std::pow(((std::pow(x-x_t, 2.0)+std::pow(y-y_t, 2.0))/(std::pow(_rG[_qp], 2.0))), _K)) + (std::pow((std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0))), _K)))))
                                        );
            }
            break;
            
        case 2: // Ring
            if(_SWITCH==0){
                _volumetric_heat[_qp] = 0;
            }
            else{
                _volumetric_heat[_qp] = (
                                            ((_Ca*_eta*_A[_qp]*_F*_P[_qp]) / (libMesh::pi* std::pow(_rT[_qp], 2.0) *_rz[_qp]  * (std::exp(-std::pow(_rR[_qp], 2.0)/(2*std::pow((_rT[_qp]/2), 2.0))) + (_rR[_qp]/(_rT[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR[_qp]/(std::sqrt(2)*(_rT[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR[_qp]),2)/(std::pow(_rT[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
                                        );
            }
            break;
        
        case 3: // Bessel
            if(_SWITCH==0){
                _volumetric_heat[_qp] = 0;
            }
            else{
                _volumetric_heat[_qp] = (
                                            // With 1 Gaussian beam and 3 ring beams with sigma replaced by R/2 
                                            ((std::pow(_Ca, 1/_K)*_K*_a0*_P[_qp]*_eta*_A[_qp]*_F) / (libMesh::pi*std::pow(_rG[_qp], 2.0)*_rz[_qp]*std::tgamma(1/_K)))*(std::exp(-_Cb*((std::pow(((std::pow(x-x_t, 2.0)+std::pow(y-y_t, 2.0))/(std::pow(_rG[_qp], 2.0))), _K)) + (std::pow((std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0))), _K)))))
                                            +
                                            ((_Ca*_eta*_A[_qp]*_F*_a1*_P[_qp]) / (libMesh::pi* std::pow(_rT1[_qp], 2.0) *_rz[_qp]  * (std::exp(-std::pow(_rR1[_qp], 2.0)/(2*std::pow((_rT1[_qp]/2), 2.0))) + (_rR1[_qp]/(_rT1[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR1[_qp]/(std::sqrt(2)*(_rT1[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR1[_qp]),2)/(std::pow(_rT1[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
                                            +
                                            ((_Ca*_eta*_A[_qp]*_F*_a2*_P[_qp]) / (libMesh::pi* std::pow(_rT2[_qp], 2.0) * _rz[_qp] * (std::exp(-std::pow(_rR2[_qp], 2.0)/(2*std::pow((_rT2[_qp]/2), 2.0))) + (_rR2[_qp]/(_rT2[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR2[_qp]/(std::sqrt(2)*(_rT2[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR2[_qp]),2)/(std::pow(_rT2[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
                                            +
                                            ((_Ca*_eta*_A[_qp]*_F*_a3*_P[_qp]) / (libMesh::pi* std::pow(_rT3[_qp], 2.0) * _rz[_qp] * (std::exp(-std::pow(_rR3[_qp], 2.0)/(2*std::pow((_rT3[_qp]/2), 2.0))) + (_rR3[_qp]/(_rT3[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR3[_qp]/(std::sqrt(2)*(_rT3[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR3[_qp]),2)/(std::pow(_rT3[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
                                        );
            }
            break;

        default:
            mooseError("Invalid beam type specified. Please use 0 for Gaussian, 1 for Flat-Top, 2 for Ring, or 3 for Bessel.");
    }

    // if(_SWITCH==0){
    //     _volumetric_heat[_qp] = 0;
    // }
    // else{
    //     _volumetric_heat[_qp] = (
    //                                 // With 1 Gaussian beam and 3 ring beams with sigma replaced by R/2 
    //                                 ((std::pow(_Ca, 1/_K)*_K*_a0*_P[_qp]*_eta*_A[_qp]*_F) / (libMesh::pi*std::pow(_rG[_qp], 2.0)*_rz[_qp]*std::tgamma(1/_K)))*(std::exp(-_Cb*((std::pow(((std::pow(x-x_t, 2.0)+std::pow(y-y_t, 2.0))/(std::pow(_rG[_qp], 2.0))), _K)) + (std::pow((std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0))), _K)))))
    //                                 +
    //                                 ((_Ca*_eta*_A[_qp]*_F*_a1*_P[_qp]) / (libMesh::pi* std::pow(_rT1[_qp], 2.0) *_rz[_qp]  * (std::exp(-std::pow(_rR1[_qp], 2.0)/(2*std::pow((_rT1[_qp]/2), 2.0))) + (_rR1[_qp]/(_rT1[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR1[_qp]/(std::sqrt(2)*(_rT1[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR1[_qp]),2)/(std::pow(_rT1[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
    //                                 +
    //                                 ((_Ca*_eta*_A[_qp]*_F*_a2*_P[_qp]) / (libMesh::pi* std::pow(_rT2[_qp], 2.0) * _rz[_qp] * (std::exp(-std::pow(_rR2[_qp], 2.0)/(2*std::pow((_rT2[_qp]/2), 2.0))) + (_rR2[_qp]/(_rT2[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR2[_qp]/(std::sqrt(2)*(_rT2[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR2[_qp]),2)/(std::pow(_rT2[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
    //                                 +
    //                                 ((_Ca*_eta*_A[_qp]*_F*_a3*_P[_qp]) / (libMesh::pi* std::pow(_rT3[_qp], 2.0) * _rz[_qp] * (std::exp(-std::pow(_rR3[_qp], 2.0)/(2*std::pow((_rT3[_qp]/2), 2.0))) + (_rR3[_qp]/(_rT3[_qp]/2))*std::sqrt(libMesh::pi/2)*std::erfc(-_rR3[_qp]/(std::sqrt(2)*(_rT3[_qp]/2)))))) * std::exp(-_Cb*((std::pow((std::sqrt(std::pow(x-x_t,2)+std::pow(y-y_t,2))-_rR3[_qp]),2)/(std::pow(_rT3[_qp], 2.0))) + (std::pow(z-z_t, 2.0)/(std::pow(_rz[_qp], 2.0)))))
    //                             );
    // }
}
