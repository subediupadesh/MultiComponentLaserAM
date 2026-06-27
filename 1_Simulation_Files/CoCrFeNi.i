## MOOSE input file codes by Upadesh Subedi date: 2025-10-23

length_scale        = 1.0e6 # micro-meters
time_scale          = 1.0e6 # micro-seconds
energy_scale        = 1.0e9 # nano-Joules

L_Power             = 350 # 370 # 400 # 420 # 470                                                            # Watts
scan_speed          = '${fparse 0.45 * length_scale/time_scale}'  # 0.5 # 0.6 # 0.7                          # m/s

v_mol               = 10.21e-6
# sigma               = 0.5  ## Surface Energy
delta               = '${fparse 10.0/length_scale}'  ## diffuse interface width
gamma               = 1.5
TAU                 = 0.2
R                   = 8.31
laser_x0            = 125
laser_y0            = 260
boltzmann_constant  = '${fparse 5.67e-8 * energy_scale/(time_scale*(length_scale)^2)}'    # Scaling J/sm^2K^4
T_inf               = 300                                                                 # K
T_melt              = 1858 ## Melting Temperature of CoCrFeNi  pyMPPELab
T0_1                = 2295 ## Reference Temperature LIQUID
T0_2                = 1058 ## ${fparse (T0_1-300)/1.8855}   ## Reference Temperature for FCC
laser_off_time      = '${fparse (1000-2*laser_x0)/scan_speed}'                           # Laser off at 'laser_x0' distance from right

y_max               = '${fparse laser_y0}'
y_min               = '${fparse laser_y0-50}'
x_max               = '${fparse laser_x0+50}'
x_min               = '${fparse laser_x0-50}'

t_mov               = 3
end_time            = '${fparse 1215/scan_speed}'
dt                  = 2 # '${fparse end_time/900}'

# cTFs                 0     1     2     3     4      
cCo_LIQ             = 0.35 #0.32 #0.30 #0.33 #0.38
cCo_FCC             = 0.28 #0.25 #0.25 #0.31 #0.30
cCr_LIQ             = 0.13 #0.15 #0.19 #0.11 #0.17
cCr_FCC             = 0.18 #0.21 #0.23 #0.15 #0.22
cFe_LIQ             = 0.15 #0.17 #0.11 #0.23 #0.19
cFe_FCC             = 0.22 #0.25 #0.20 #0.27 #0.26

gravity         = '${fparse -9.81 * length_scale/time_scale^2}'

[Mesh]
    [mesh]
        type        = GeneratedMeshGenerator
        dim         = 2
        nx          = 50
        ny          = 26
        xmin        = 0
        xmax        = 1000
        ymin        = 0
        ymax        = ${laser_y0}
        elem_type   = QUAD9
        # uniform_refine = 2
    []

    [TopLayer]
        input       = 'mesh'
        type        = SubdomainBoundingBoxGenerator
        bottom_left = '0         0         0'
        top_right   = '1000      200       0'
        block_id    = '1'
        block_name  = 'solid'
    []    

    [BottomLayer]
        input       = 'TopLayer'
        type        = SubdomainBoundingBoxGenerator
        bottom_left = '0         200            0'
        top_right   = '1000      ${laser_y0}    0'
        block_id    = 2
        block_name  = 'liquid'
    []
[]

[Variables]
    [temp]
        initial_condition = 300
    []

    [vel_x]
        order   = SECOND
        family  = LAGRANGE
    []

    [vel_y]
        order   = SECOND
        family  = LAGRANGE
    []
    
    [p]
        order   = FIRST
        family  = LAGRANGE
    []

    [wA]
        order   = FIRST
        family  = LAGRANGE
    []

    [wB]
        order   = FIRST
        family  = LAGRANGE
    []

    [wC]
        order   = FIRST
        family  = LAGRANGE
    []

    [cA] # global concentration for Co
        order   = FIRST
        family  = LAGRANGE
    []

    [cB] # global concentration for Cr
        order   = FIRST
        family  = LAGRANGE
    []

    [cC] # global concentration for Fe
        order   = FIRST
        family  = LAGRANGE
    []

    [cA1]
        order   = FIRST
        family  = LAGRANGE
    []

    [cA2]
        order   = FIRST
        family  = LAGRANGE
    []

    [cB1]
        order   = FIRST
        family  = LAGRANGE
    []

    [cB2]
        order   = FIRST
        family  = LAGRANGE
    []

    [cC1]
        order   = FIRST
        family  = LAGRANGE
    []

    [cC2]
        order = FIRST
        family = LAGRANGE
    []

    [eta1]
        order   = FIRST
        family  = LAGRANGE
    []

    [eta2]
        order   = FIRST
        family  = LAGRANGE
    []
[]


[ICs]
    [velocity_x]
        variable    = 'vel_x'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, 1e-2, 1e-12)' 
    []

    [velocity_y]
        variable    = 'vel_y'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, 1e-2, 1e-12)' 
    []

    [eta1]
        variable    = 'eta1'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, 1, 0)'
    []

    [eta2]
        variable    = 'eta2'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, 0, 1)'
    []

    [cA]  # Global variable for Co-rich region
        variable    = 'cA'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, ${cCo_LIQ}, ${cCo_FCC})'
    []

    [cB]  # Global variable for Cr-rich region
        variable    = 'cB'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, ${cCr_LIQ}, ${cCr_FCC})'
    []

    [cC]  # Global variable for Fe-rich region
        variable    = 'cC'
        type        = FunctionIC
        function    = 'if(y>${y_min}&y<=${y_max} & x>=${x_min}&x<=${x_max}, ${cFe_LIQ}, ${cFe_FCC})'
    []

[]

[BCs]

    [radiation_flux]
        type                        = FunctionRadiativeBC
        variable                    = 'temp'
        boundary                    = 'left top right bottom'
        emissivity_function         = '(50*${energy_scale}/(${time_scale}*${length_scale}^2))/(${boltzmann_constant}*4*${T_inf}^3)'  ##https://mooseframework.inl.gov/source/bcs/FunctionRadiativeBC.html
        Tinfinity                   = '${T_inf}'
        stefan_boltzmann_constant   = '${boltzmann_constant}'
    []

    [convectiveFlux_air]
        type                        = ConvectiveHeatFluxBC
        variable                    = 'temp'
        boundary                    = 'left top right'
        T_infinity                  = '${T_inf}'
        heat_transfer_coefficient   = '${fparse 50* energy_scale/(time_scale*length_scale^2)}' # 50 W/m^2K for air  https://doi.org/10.1533/978-1-78242-164-1.353
        heat_transfer_coefficient_dT = 0
    []

    [convectiveFlux_left]
        type                        = ConvectiveHeatFluxBC
        variable                    = 'temp'
        boundary                    = 'bottom'
        T_infinity                  = '${T_inf}'
        heat_transfer_coefficient   = '${fparse 11500* energy_scale/(time_scale*length_scale^2)}' # 11500 W/m^2K for metal  https://doi.org/10.1016/j.intermet.2017.11.021
        heat_transfer_coefficient_dT = 0
    []

    [neumann1]
        type                        = NeumannBC
        boundary                    = 'bottom'
        variable                    = 'eta1'
        value                       = 0
    []

    [vel_x_bottom]
        type                        = ADDirichletBC
        variable                    = 'vel_x'
        boundary                    = 'left bottom right'
        value                       = 0
    []

    [vel_y_bottom]
        type                        = ADDirichletBC
        variable                    = 'vel_y'
        boundary                    = 'left bottom right'
        value                       = 0
    []
[]


[Functions]
    [path_x]
        type            = ParsedFunction
        expression      = 'if(t<=${t_mov}, ${laser_x0}, ${laser_x0}+${scan_speed}*(t-${t_mov}))'
        # expression      = 'if(temp_max <= ${T_melt}, ${laser_x0}, ${laser_x0}+${scan_speed}*t)'
        # symbol_names    = 'temp_max'
        # symbol_values   = 'temp_max'
    []

    [path_y]
        type        = ConstantFunction
        value       = '${laser_y0}'
    []

    [laser_switch]
        type        = ParsedFunction
        expression  = 'if(t<${laser_off_time}, 1, 0)'
    []

    [pow_att] # Power attenuation factor at beginning (3 micro-sec) for proper melting of the surface and then after the laser moves away, the power is reduced to normal afterwards
        type        = ParsedFunction
        expression  = 'if(t<=${t_mov}, 10, 1)'
    []
[]


[Materials]

    [mu_values]
        type                    = GenericConstantMaterial
        prop_names              = 'pseudo_mu1       mu2'  # mu_m ==> mushy zone
        prop_values             = '9.33743418e-04  3.11e-0' 
    []

    [mu_LIQ]
        type                    = ParsedMaterial
        property_name           = 'mu1'
        constant_names          = 'Q_mu'
        constant_expressions    = '2669'
        coupled_variables       = 'temp'
        expression              = 'exp(-0.1990 + (Q_mu/temp)) / 1000' # The unit is in milli-Pascal-sec so divide by 1000 to convert to Pa.s # https://link.springer.com/article/10.1007/s10765-016-2104-7
        outputs                 = 'exodus'
    []

    [mu_NS]
        type                    = ParsedMaterial
        property_name           = 'mu_name'
        material_property_names = 'mu1 mu2 h1 h2'
        expression              = '(h1*mu1 + 10*mu1*h1*h2 + h2*mu2) / (${length_scale}*${time_scale})'
        outputs                 = 'exodus'
    [] 


    [conductivity_values] # Thermal conductivity of 2 phases
        type                    = GenericConstantMaterial
        prop_names              = 'k1                                               k2'
        prop_values             = '${fparse (78+35+41+35)/4}         ${fparse (100+94+65+91)/4}'
    []

    [conductivity]
        type                    = ParsedMaterial
        property_name           = 'thermal_conductivity'
        material_property_names = 'k1 k2 h1 h2'
        expression              = '(h1*k1 + h2*k2) * ${energy_scale}/(${length_scale}*${time_scale})'
        block                   = 'solid liquid'
    []

    [density_values] # Density of phases
        type                    = GenericConstantMaterial
        prop_names              = 'rho1                                                     rho2'
        prop_values             = '${fparse 1000*(7.75+6.3+7.1+7.91)/4}                 ${fparse 1000*(8.9+7.19+7.874+8.9)/4}'
    []

    [density]
        type                    = ParsedMaterial
        property_name           = 'density_name'
        material_property_names = 'rho1 rho2 h1 h2'
        expression              = '(h1*rho1 + h2*rho2)/(${length_scale}^3)'
        block                   = 'solid liquid'
    []

    [spec_heat_values] # Specific Heat of phases
        type                    = GenericConstantMaterial
        prop_names              = 'sp1  sp2'
        prop_values             = '${fparse (418.68+50+449+39.39)/4}         ${fparse (421+448+820+444)/4}'
    []

    [specific_heat]
        type                    = ParsedMaterial
        property_name           = 'specific_heat'
        material_property_names = 'sp1 sp2 h1 h2'
        expression              = '(h1*sp1 + h2*sp2)*${energy_scale}'
        block                   = 'solid liquid'
    []

    [absorptivity_value]
        type                    = ParsedMaterial
        property_name           = 'absorptivity'
        expression              = '3.5e3/${length_scale}'
    []

    [Gaussian_Beam_Radius]
        type                    = ParsedMaterial
        property_name           = 'rG'
        expression              = '40.0e-6*${length_scale}'
    []

    [power_attenuation]
        type                    = GenericFunctionMaterial
        prop_names              = 'pAtt'
        prop_values             = 'pow_att'
    []

    [laser_power]
        type                    = ParsedMaterial
        property_name           = 'P'
        material_property_names = 'pAtt'
        expression              = 'pAtt*${L_Power}*${energy_scale}/${time_scale}'
        outputs                 = 'exodus'
    []

    [volumetric_heat]
        type                    = LaserSource
        beam_type               = 'Gaussian'
        power                   = 'P'
        efficiency              = '0.75'
        Ca                      = '2.0'
        Cb                      = '2.0'
        rG                      = 'rG'
        alpha                   = 'absorptivity'
        function_x              = 'path_x'
        function_y              = 'path_y'
        laser_switch            = 'laser_switch' # Laser switch 1 for ON and 0 for OFF
    []

    [constants]
        type                    = GenericConstantMaterial
        prop_names              = 'M_eta1    M_eta2'
        prop_values             = '2e-12    1e-16'
    []

    [interface_energy]
        type                    = ParsedMaterial
        coupled_variables       = 'cA cB cC'
        property_name           = 'sigma'
        constant_names          = 'w1       w2     w3   w4'
        constant_expressions    = '0.05     0.75    0.08  0.02'
        expression              = '10*(cA*w1 + cB*w2 + cC*w3 + (1-cA-cB-cC)*w4)'
        outputs                 = 'exodus'
    []

    [F_LIQUID]
        type                    = DerivativeParsedMaterial
        property_name           = 'F1'
        coupled_variables       = 'temp cA1 cB1 cC1'
        constant_names          = 'factor1   a1    b1     c1     d1    e1    t1       T1       ca1     cb1     cc1'
        constant_expressions    = '10        20    18    22   -10     0   5e-5    ${T0_1}   ${cCo_LIQ}    ${cCr_LIQ}    ${cFe_LIQ}'
        expression              = 'factor1*(a1*(cA1-ca1)^2 + b1*(cB1-cb1)^2 + c1*(cC1-cc1)^2 + t1*(temp-T1)^2 + d1) *${energy_scale}/(${v_mol}*${length_scale}^3)'
        outputs                 = 'exodus'
        derivative_order        = 2
    []

    [F_FCC]
        type                    = DerivativeParsedMaterial
        property_name           = 'F2'
        coupled_variables       = 'temp cA2 cB2 cC2'
        constant_names          = 'factor2    a2     b2     c2     d2    e2    t2        T2      ca2    cb2    cc2'
        constant_expressions    = '10        15     42    17    -10    0    1.5e-5    ${T0_2}  ${cCo_FCC}   ${cCr_FCC}   ${cFe_FCC}'
        expression              = 'factor2*(a2*(cA2-ca2)^2 + b2*(cB2-cb2)^2 + c2*(cC2-cc2)^2 + t2*(temp-T2)^2 + d2) *${energy_scale}/(${v_mol}*${length_scale}^3)'
        outputs                 = 'exodus'
        derivative_order        = 2
    []

    # [F_1_test]
    #     type                    = DerivativeParsedMaterial
    #     property_name           = 'F1_test'
    #     constant_names          = 'FactorT1'
    #     constant_expressions    = '1'
    #     coupled_variables       = 'temp cA1 cB1 cC1'
    #     expression              = 'FactorT1*(909.0*cA1*cB1*(cA1 - cB1) - 16000.0*cA1*cB1*(cA1 + (1/3)*cC1)*(-cA1 - cB1 - cC1 + 1) - 16000.0*cA1*cB1*(cB1 + (1/3)*cC1)*(-cA1 - cB1 - cC1 + 1) + 1.0*cA1*cB1*(-5.624*temp - 3034.0) - 16000.0*cA1*cB1*(-cA1 - cB1 - cC1 + 1)*(-cA1 - cB1 - 2/3*cC1 + 1) - 1752.0*cA1*cC1*(cA1 - cC1) - 9312.0*cA1*cC1 + 1331.0*cA1*(-cA1 - cB1 - cC1 + 1) + 1.0*cA1*if(temp < 1768.0,-8.931932*temp - 2.19801e-21*temp^7.0 + if(temp < 1768.0,72527.0*temp^(-1.0) - 25.0861*temp*log(temp) + 133.36601*temp - 0.002654739*temp^2.0 - 1.7348e-7*temp^3.0 + 310.241,9.3488e+30*temp^(-9.0) - 40.5*temp*log(temp) + 253.28374*temp - 17197.666) + 15085.037,-9.3488e+30*temp^(-9.0) - 9.683796*temp + if(temp < 1768.0,72527.0*temp^(-1.0) - 25.0861*temp*log(temp) + 133.36601*temp - 0.002654739*temp^2.0 - 1.7348e-7*temp^3.0 + 310.241,9.3488e+30*temp^(-9.0) - 40.5*temp*log(temp) + 253.28374*temp - 17197.666) + 16351.056) + 36583.0*cB1*cC1*((1/3)*cA1 + cB1)*(-cA1 - cB1 - cC1 + 1) + 13254.0*cB1*cC1*((1/3)*cA1 + cC1)*(-cA1 - cB1 - cC1 + 1) - 1331.0*cB1*cC1*(cB1 - cC1) + 1.0*cB1*cC1*(7.996546*temp - 17737.0) - 10018.0*cB1*cC1*(-cA1 - cB1 - cC1 + 1)*(-2/3*cA1 - cB1 - cC1 + 1) + 1.0*cB1*(318.0 - 7.3318*temp)*(-cA1 - cB1 - cC1 + 1) + 1.0*cB1*(16941.0 - 6.3696*temp)*(-cA1 - cB1 - cC1 + 1)*(cA1 + 2*cB1 + cC1 - 1) + 1.0*cB1*(7.653e-6*2.71828182845905^(1.7e-5*temp + 9.2e-9*temp^2.0 - 1e200) + if(temp < 2180.0,-11.420225*temp + 2.37615e-21*temp^7.0 + if(temp < 2180.0,139250.0*temp^(-1.0) - 26.908*temp*log(temp) + 157.48*temp + 0.00189435*temp^2.0 - 1.47721e-6*temp^3.0 - 8856.94,-2.88526e+32*temp^(-9.0) - 50.0*temp*log(temp) + 344.18*temp - 34869.344) + 24339.955,-50.0*temp*log(temp) + 335.616316*temp - 16459.984)) + 1.0*cC1*(10180.0 - 4.146656*temp)*(-cA1 - cB1 - cC1 + 1)*(cA1 + cB1 + 2*cC1 - 1) + 1.0*cC1*(6.46677e-6*2.71828182845905^(0.0001135*temp - 1.0*log(2.71569924e-14*temp + 4.22534787e-12) - 1e200) + if(temp < 1811.0,-6.55843*temp - 3.6751551e-21*temp^7.0 + if(temp < 1811.0,77359.0*temp^(-1.0) - 23.5143*temp*log(temp) + 124.134*temp - 0.00439752*temp^2.0 - 5.8927e-8*temp^3.0 + 1225.7,2.29603e+31*temp^(-9.0) - 46.0*temp*log(temp) + 299.31255*temp - 25383.581) + 12040.17,-46.0*temp*log(temp) + 291.302*temp - 10838.83)) + 1.0*cC1*(5.1622*temp - 16911.0)*(-cA1 - cB1 - cC1 + 1) + 8.3145*temp*(1.0*if(cA1 > 1.0e-15,cA1*log(cA1),0) + 1.0*if(cB1 > 1.0e-15,cB1*log(cB1),0) + 1.0*if(cC1 > 1.0e-15,cC1*log(cC1),0) + 1.0*if(cA1 + cB1 + cC1 < 0.999999999999999,(-cA1 - cB1 - cC1 + 1)*log(-cA1 - cB1 - cC1 + 1),0)) + 1.0*(-cA1 - cB1 - cC1 + 1)*if(temp < 1728.0,-9.397*temp - 3.82318e-21*temp^7.0 + if(temp < 1728.0,-22.096*temp*log(temp) + 117.854*temp - 0.0048407*temp^2.0 - 5179.159,1.12754e+31*temp^(-9.0) - 43.1*temp*log(temp) + 279.135*temp - 27840.655) + 16414.686,-1.12754e+31*temp^(-9.0) - 10.537*temp + if(temp < 1728.0,-22.096*temp*log(temp) + 117.854*temp - 0.0048407*temp^2.0 - 5179.159,1.12754e+31*temp^(-9.0) - 43.1*temp*log(temp) + 279.135*temp - 27840.655) + 18290.88))*${energy_scale}/(${v_mol}*${length_scale}^3)'
    #     outputs                 = 'exodus'
    # []

    # [F_2_test]
    #     type                    = DerivativeParsedMaterial
    #     property_name           = 'F2_test'
    #     constant_names          = 'FactorT2'
    #     constant_expressions    = '1'
    #     coupled_variables       = 'temp cA2 cB2 cC2'
    #     expression              = 'FactorT2*(3000.0*cA2*cB2*cC2*(-1/3*cA2 - 1/3*cB2 + (2/3)*cC2 + 1/3) + 3000.0*cA2*cB2*cC2*(-1/3*cA2 + (2/3)*cB2 - 1/3*cC2 + 1/3) + 3000.0*cA2*cB2*cC2*((2/3)*cA2 - 1/3*cB2 - 1/3*cC2 + 1/3) + 1.0*cA2*cB2*(1500.0 - 9.592*temp) + 1.0*cA2*cB2*(cA2 + (1/3)*cC2)*(13.533*temp - 40710.0)*(-cA2 - cB2 - cC2 + 1) + 1.0*cA2*cB2*(cB2 + (1/3)*cC2)*(13.533*temp - 40710.0)*(-cA2 - cB2 - cC2 + 1) + 1.0*cA2*cB2*(13.533*temp - 40710.0)*(-cA2 - cB2 - cC2 + 1)*(-cA2 - cB2 - 2/3*cC2 + 1) + 1.0*cA2*cC2*(1181.0 - 1.6544*temp)*(cA2 - cC2) - 8471.0*cA2*cC2 + 1.0*cA2*(1.2629*temp - 800.0)*(-cA2 - cB2 - cC2 + 1) + 1.0*cA2*(-0.615248*temp + if(temp < 1768.0,72527.0*temp^(-1.0) - 25.0861*temp*log(temp) + 133.36601*temp - 0.002654739*temp^2.0 - 1.7348e-7*temp^3.0 + 310.241,9.3488e+30*temp^(-9.0) - 40.5*temp*log(temp) + 253.28374*temp - 17197.666) + 427.591) + 1.0*cB2*cC2*(10833.0 - 7.477*temp) + 1.0*cB2*cC2*(16580.0 - 9.783*temp)*((1/3)*cA2 + cB2)*(-cA2 - cB2 - cC2 + 1) + 1.0*cB2*cC2*(16580.0 - 9.783*temp)*((1/3)*cA2 + cC2)*(-cA2 - cB2 - cC2 + 1) + 1.0*cB2*cC2*(16580.0 - 9.783*temp)*(-cA2 - cB2 - cC2 + 1)*(-2/3*cA2 - cB2 - cC2 + 1) + 1410.0*cB2*cC2*(cB2 - cC2) + 1.0*cB2*(8030.0 - 12.8801*temp)*(-cA2 - cB2 - cC2 + 1) + 1.0*cB2*(33080.0 - 16.0362*temp)*(-cA2 - cB2 - cC2 + 1)*(cA2 + 2*cB2 + cC2 - 1) + 1.0*cB2*(7.188e-6*2.71828182845905^(1.7e-5*temp + 9.2e-9*temp^2.0 + 11.5260881880362) + 0.163*temp + if(temp < 2180.0,139250.0*temp^(-1.0) - 26.908*temp*log(temp) + 157.48*temp + 0.00189435*temp^2.0 - 1.47721e-6*temp^3.0 - 8856.94,-2.88526e+32*temp^(-9.0) - 50.0*temp*log(temp) + 344.18*temp - 34869.344) + 7284.0) + 1.0*cC2*(11082.13 - 4.45077*temp)*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 1.0*cC2*(6.688726e-6*2.71828182845905^(7.3097e-5*temp + log(2.71828182845905^(0.8064454*log(3.41067861456e-11*temp + 1.00000329545723)) - 1.0) - 1.0*log(2.71455808e-16*temp + 2.62285341e-11)) + if(temp < 1811.0,-1.15*temp*log(temp) + 8.282*temp + 0.00064*temp^2.0 + if(temp < 1811.0,77359.0*temp^(-1.0) - 23.5143*temp*log(temp) + 124.134*temp - 0.00439752*temp^2.0 - 5.8927e-8*temp^3.0 + 1225.7,2.29603e+31*temp^(-9.0) - 46.0*temp*log(temp) + 299.31255*temp - 25383.581) - 1462.4,4.9251e+30*temp^(-9.0) + 0.94001*temp + if(temp < 1811.0,77359.0*temp^(-1.0) - 23.5143*temp*log(temp) + 124.134*temp - 0.00439752*temp^2.0 - 5.8927e-8*temp^3.0 + 1225.7,2.29603e+31*temp^(-9.0) - 46.0*temp*log(temp) + 299.31255*temp - 25383.581) - 1713.815)) + 1.0*cC2*(3.27413*temp - 12054.355)*(-cA2 - cB2 - cC2 + 1) - 725.805174*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1)^2 + 8.3145*temp*(1.0*if(cA2 > 1.0e-15,cA2*log(cA2),0) + 1.0*if(cB2 > 1.0e-15,cB2*log(cB2),0) + 1.0*if(cC2 > 1.0e-15,cC2*log(cC2),0) + 1.0*if(cA2 + cB2 + cC2 < 0.999999999999999,(-cA2 - cB2 - cC2 + 1)*log(-cA2 - cB2 - cC2 + 1),0)) + 8.3145*temp*if(temp < 598.333333333333*cA2*cB2 - 293.0*cA2*cC2*(cA2 - cC2) - 94.3333333333333*cA2*cC2 + 33.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 137.0*cA2*(-cA2 - cB2 - cC2 + 1) - 254.333333333333*cA2 + 1201.66666666667*cB2*(-cA2 - cB2 - cC2 + 1) + 580.666666666667*cB2 + 227.333333333333*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 711.0*cC2*(-cA2 - cB2 - cC2 + 1) + 278.0*cC2 - 211.0,-1.10920907678494e-49*temp^15/(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^15 - 1.48434544024743e-30*temp^9/(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^9 - 1.00559148405736e-10*temp^3/(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^3 + 1 - 0.86033875460538*(598.333333333333*cA2*cB2 - 293.0*cA2*cC2*(cA2 - cC2) - 94.3333333333333*cA2*cC2 + 33.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 137.0*cA2*(-cA2 - cB2 - cC2 + 1) - 254.333333333333*cA2 + 1201.66666666667*cB2*(-cA2 - cB2 - cC2 + 1) + 580.666666666667*cB2 + 227.333333333333*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 711.0*cC2*(-cA2 - cB2 - cC2 + 1) + 278.0*cC2 - 210.999999999)/temp,if(temp < -1795.0*cA2*cB2 + 879.0*cA2*cC2*(cA2 - cC2) + 283.0*cA2*cC2 - 99.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 411.0*cA2*(-cA2 - cB2 - cC2 + 1) + 763.0*cA2 - 3605.0*cB2*(-cA2 - cB2 - cC2 + 1) - 1742.0*cB2 - 682.0*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 2133.0*cC2*(-cA2 - cB2 - cC2 + 1) - 834.0*cC2 + 633.0,-7.73026877088923e-57*temp^15/(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^15 - 7.54125611058998e-35*temp^9/(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^9 - 3.72441290391614e-12*temp^3/(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^3 + 1 - 0.86033875460538*(-1795.0*cA2*cB2 + 879.0*cA2*cC2*(cA2 - cC2) + 283.0*cA2*cC2 - 99.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 411.0*cA2*(-cA2 - cB2 - cC2 + 1) + 763.0*cA2 - 3605.0*cB2*(-cA2 - cB2 - cC2 + 1) - 1742.0*cB2 - 682.0*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 2133.0*cC2*(-cA2 - cB2 - cC2 + 1) - 834.0*cC2 + 633.000000001)/temp,if(temp > -1795.0*cA2*cB2 + 879.0*cA2*cC2*(cA2 - cC2) + 283.0*cA2*cC2 - 99.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 411.0*cA2*(-cA2 - cB2 - cC2 + 1) + 763.0*cA2 - 3605.0*cB2*(-cA2 - cB2 - cC2 + 1) - 1742.0*cB2 - 682.0*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 2133.0*cC2*(-cA2 - cB2 - cC2 + 1) - 834.0*cC2 + 633.0 & 1795.0*cA2*cB2 - 879.0*cA2*cC2*(cA2 - cC2) - 283.0*cA2*cC2 + 99.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 411.0*cA2*(-cA2 - cB2 - cC2 + 1) - 763.0*cA2 + 3605.0*cB2*(-cA2 - cB2 - cC2 + 1) + 1742.0*cB2 + 682.0*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 2133.0*cC2*(-cA2 - cB2 - cC2 + 1) + 834.0*cC2 - 633.0 < 0,-2.59929042790719e+16*(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^5/temp^5 - 3.05912303493199e+50*(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^15/temp^15 - 2.38160059162011e+85*(-0.497919556171983*cA2*cB2 + 0.243828016643551*cA2*cC2*(cA2 - cC2) + 0.078502080443828*cA2*cC2 - 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) + 0.211650485436893*cA2 - cB2*(-cA2 - cB2 - cC2 + 1) - 0.483217753120666*cB2 - 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 0.591678224687933*cC2*(-cA2 - cB2 - cC2 + 1) - 0.231345353675451*cC2 + 0.175589459084882)^25/temp^25,if(temp > 598.333333333333*cA2*cB2 - 293.0*cA2*cC2*(cA2 - cC2) - 94.3333333333333*cA2*cC2 + 33.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 137.0*cA2*(-cA2 - cB2 - cC2 + 1) - 254.333333333333*cA2 + 1201.66666666667*cB2*(-cA2 - cB2 - cC2 + 1) + 580.666666666667*cB2 + 227.333333333333*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 711.0*cC2*(-cA2 - cB2 - cC2 + 1) + 278.0*cC2 - 211.0 & 1795.0*cA2*cB2 - 879.0*cA2*cC2*(cA2 - cC2) - 283.0*cA2*cC2 + 99.0*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 411.0*cA2*(-cA2 - cB2 - cC2 + 1) - 763.0*cA2 + 3605.0*cB2*(-cA2 - cB2 - cC2 + 1) + 1742.0*cB2 + 682.0*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 2133.0*cC2*(-cA2 - cB2 - cC2 + 1) + 834.0*cC2 - 633.0 > 0,-106966684276016.0*(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^5/temp^5 - 2.13195544087921e+43*(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^15/temp^15 - 2.81084929630501e+73*(0.497919556171983*cA2*cB2 - 0.243828016643551*cA2*cC2*(cA2 - cC2) - 0.078502080443828*cA2*cC2 + 0.0274618585298197*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) - 0.114008321775312*cA2*(-cA2 - cB2 - cC2 + 1) - 0.211650485436893*cA2 + cB2*(-cA2 - cB2 - cC2 + 1) + 0.483217753120666*cB2 + 0.189181692094313*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) - 0.591678224687934*cC2*(-cA2 - cB2 - cC2 + 1) + 0.231345353675451*cC2 - 0.175589459083773)^25/temp^25,0))))*log((-3.516*cA2*cC2*(cA2 - cC2) + 9.74*cA2*cC2 + 0.165*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 1.046*cA2*(-cA2 - cB2 - cC2 + 1) + 0.83*cA2 - 1.91*cB2*(-cA2 - cB2 - cC2 + 1) - 2.98*cB2 + 6.18*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1)^3 + 5.93*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1)^2 + 7.23*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 9.55*cC2*(-cA2 - cB2 - cC2 + 1) - 2.62*cC2 + 0.52)*if(-3.516*cA2*cC2*(cA2 - cC2) + 9.74*cA2*cC2 + 0.165*cA2*(-cA2 - cB2 - cC2 + 1)*(2*cA2 + cB2 + cC2 - 1) + 1.046*cA2*(-cA2 - cB2 - cC2 + 1) + 0.83*cA2 - 1.91*cB2*(-cA2 - cB2 - cC2 + 1) - 2.98*cB2 + 6.18*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1)^3 + 5.93*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1)^2 + 7.23*cC2*(-cA2 - cB2 - cC2 + 1)*(cA2 + cB2 + 2*cC2 - 1) + 9.55*cC2*(-cA2 - cB2 - cC2 + 1) - 2.62*cC2 + 0.52 <= 0,-0.333333333333333,1.0) + 1) + 1.0*(-cA2 - cB2 - cC2 + 1)*if(temp < 1728.0,-22.096*temp*log(temp) + 117.854*temp - 0.0048407*temp^2.0 - 5179.159,1.12754e+31*temp^(-9.0) - 43.1*temp*log(temp) + 279.135*temp - 27840.655)) *${energy_scale}/(${v_mol}*${length_scale}^3)' 
    #     outputs                 = 'exodus'
    # []    
    
    [h1]
        type                    = SwitchingFunctionMultiPhaseMaterial
        h_name                  = 'h1'
        all_etas                = 'eta1 eta2'
        phase_etas              = 'eta1'
    []

    [h2]
        type                    = SwitchingFunctionMultiPhaseMaterial
        h_name                  = 'h2'
        all_etas                = 'eta1 eta2'
        phase_etas              = 'eta2'
    []

    [g1]
        type                    = BarrierFunctionMaterial
        g_order                 = 'SIMPLE'
        eta                     = 'eta1'
        function_name           = 'g1'
    []

    [g2]
        type                    = BarrierFunctionMaterial
        g_order                 = 'SIMPLE'
        eta                     = 'eta2'
        function_name           = 'g2'
    []  

    [mu]
        type                    = ParsedMaterial
        property_name           = 'mu'
        material_property_names = 'sigma'
        expression              = '6*(sigma/${delta})*(${energy_scale}/${length_scale}^3)'
        outputs                 = 'exodus'
    []

    [kappa]
        type                    = ParsedMaterial
        property_name           = 'kappa'
        material_property_names = 'sigma'
        expression              = '3/4*(sigma*${delta})*(${energy_scale}/${length_scale})'
        outputs                 = 'exodus'
    []

    [Mobility_eta1]
        type                    = ParsedMaterial
        property_name           = 'M1'
        material_property_names = 'M_eta1'
        expression              = 'M_eta1*(${length_scale}^5/(${time_scale}*${energy_scale}))'
    []

    [Mobility_eta2]
        type                    = ParsedMaterial
        property_name           = 'M2'
        material_property_names = 'M_eta2'
        expression              = 'M_eta2*(${length_scale}^5/(${time_scale}*${energy_scale}))'
    []

    [Mobility]
        type                    = ParsedMaterial
        property_name           = 'M'
        constant_names          = 'factor_M'
        constant_expressions    = '1.0e0'
        material_property_names = 'M1 M2 h1 h2'
        expression              = 'factor_M*(h1*M1 + h2*M2)'
        outputs                 = 'exodus'
    []

    [L1-2]
        type                    = ParsedMaterial
        property_name           = 'L1_2'
        constant_names          = 'factor_L'
        constant_expressions    = '1.0e-1'
        material_property_names = 'M1 M2 mu kappa'
        expression              = 'factor_L*(4/3)*(mu/kappa)*((M1+M2)/(2*${TAU}))'
        outputs                 = 'exodus'
    []

    [Interface_Mobility]
        type                    = ParsedMaterial
        property_name           = 'L'
        coupled_variables       = 'eta1 eta2'
        material_property_names = 'L1_2 h1 h2'
        expression              = 'L1_2*h1*h2'
        outputs                 = 'exodus'
    []

[]

[Kernels]

    [mass]
        type                    = INSMass
        variable                = 'p'
        u                       = 'vel_x'
        v                       = 'vel_y'
        pressure                = 'p'
        mu_name                 = 'mu_name'
        rho_name                = 'density_name'
    []

    [x_momentum_space]
        type                    = INSMomentumLaplaceForm
        variable                = 'vel_x'
        u                       = 'vel_x'
        v                       = 'vel_y'
        pressure                = 'p'
        mu_name                 = 'mu_name'
        rho_name                = 'density_name'
        gravity                 = '0 ${gravity} 0'
        supg                    = true
        component               = 0
        integrate_p_by_parts    = true
    []

    [y_momentum_space]
        type                    = INSMomentumLaplaceForm
        variable                = 'vel_y'
        u                       = 'vel_x'
        v                       = 'vel_y'
        pressure                = 'p'
        mu_name                 = 'mu_name'
        rho_name                = 'density_name'
        gravity                 = '0 ${gravity} 0'
        supg                    = true
        component               = 1
        integrate_p_by_parts    = true
    []

    [x_momentum_time]
        type                    = INSMomentumTimeDerivative
        variable                = 'vel_x' 
        rho_name                = 'density_name'
    []
    
    [y_momentum_time]
        type                    = INSMomentumTimeDerivative
        variable                = 'vel_y'
        rho_name                = 'density_name'
    []

    [temperature_time]
        type                    = INSTemperatureTimeDerivative
        variable                = 'temp'
        cp_name                 = 'specific_heat'
        rho_name                = 'density_name'
    []

    [time]
        type                    = HeatConductionTimeDerivative
        variable                = 'temp'
        density_name            = 'density_name'
        specific_heat           = 'specific_heat'
    []

    [heat_conduct]
        type                    = HeatConduction
        variable                = 'temp'
        diffusion_coefficient   = 'thermal_conductivity'
    []

    [heat_source]
        type                    = ADMatHeatSource
        material_property       = 'volumetric_heat'
        variable                = 'temp'
    []

    [chempotA12]
        type                    = KKSPhaseChemicalPotential
        variable                = 'cA1'
        cb                      = 'cA2'
        fa_name                 = 'F1'
        fb_name                 = 'F2'
        args_a                  = 'cB1 cC1 temp'  # Reference Taken from https://github.com/idaholab/moose/blob/next/modules/phase_field/examples/kim-kim-suzuki/kks_example_ternary.i
        args_b                  = 'cB2 cC2'
    []

    [chempotB12]
        type                    = KKSPhaseChemicalPotential
        variable                = 'cB1'
        cb                      = 'cB2'
        fa_name                 = 'F1'
        fb_name                 = 'F2'
        args_a                  = 'cA1 cC1 temp'
        args_b                  = 'cA2 cC2'
    []

    [chempotC12]
        type                    = KKSPhaseChemicalPotential
        variable                = 'cC1'
        cb                      = 'cC2'
        fa_name                 = 'F1'
        fb_name                 = 'F2'
        args_a                  = 'cA1 cB1 temp'
        args_b                  = 'cA2 cB2'
    []

    [phaseconcentration_A]
        type                    = KKSMultiPhaseConcentration
        variable                = 'cA2'
        cj                      = 'cA1 cA2'
        hj_names                = 'h1 h2'
        etas                    = 'eta1 eta2'
        c                       = 'cA'
    []

    [phaseconcentration_B]
        type                    = KKSMultiPhaseConcentration
        variable                = 'cB2'
        cj                      = 'cB1 cB2'
        hj_names                = 'h1 h2'
        etas                    = 'eta1 eta2'
        c                       = 'cB'
    []

    [phaseconcentration_C]
        type                    = KKSMultiPhaseConcentration
        variable                = 'cC2'
        cj                      = 'cC1 cC2'
        hj_names                = 'h1 h2'
        etas                    = 'eta1 eta2'
        c                       = 'cC'
    []

    [CHBulk_A]
        type                    = KKSSplitCHCRes
        variable                = 'cA'
        ca                      = 'cA2'
        fa_name                 = 'F2'
        w                       = 'wA'
        args_a                  = 'cB2 cC2 temp'
    []

    [CHBulk_B]
        type                    = KKSSplitCHCRes
        variable                = 'cB'
        ca                      = 'cB2'       
        fa_name                 = 'F2'
        w                       = 'wB'
        args_a                  = 'cC2 cA2 temp'
    []

    [CHBulk_C]
        type                    = KKSSplitCHCRes
        variable                = 'cC'
        ca                      = 'cC2'       
        fa_name                 = 'F2'
        w                       = 'wC'
        args_a                  = 'cA2 cB2 temp'
    []

    [dcAdt] # Gives dcA/dt
        type                    = CoupledTimeDerivative
        variable                = 'wA'
        v                       = 'cA'
    []

    [dcBdt] # Gives dcB/dt
        type                    = CoupledTimeDerivative
        variable                = 'wB'
        v                       = 'cB'
    []

    [dcCdt] # Gives dcC/dt
        type                    = CoupledTimeDerivative
        variable                = 'wC'
        v                       = 'cC'
    []

    [cAkernel]
        type                    = SplitCHWRes
        mob_name                = 'M'
        variable                = 'wA'
        coupled_variables       = 'eta1 eta2 temp'
    []

    [cBkernel]
        type                    = SplitCHWRes
        mob_name                = 'M'
        variable                = 'wB'
        coupled_variables       = 'eta1 eta2 temp'
    []

    [cCkernel]
        type                    = SplitCHWRes
        mob_name                = 'M'
        variable                = 'wC'
        coupled_variables       = 'eta1 eta2 temp'
    []

  # Kernels for Allen-Cahn equation for eta1
    [deta1dt]
        type                    = TimeDerivative
        variable                = 'eta1'
    []

    [ACBulkF1]
        type                    = KKSMultiACBulkF
        variable                = 'eta1'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        gi_name                 = 'g1'
        eta_i                   = 'eta1'
        wi                      = 5e-3
        coupled_variables       = 'cA1 cA2 cB1 cB2 cC1 cC2 eta2 temp'
        mob_name                = 'L'
    []
        
    [ACBulkC1A]
        type                    = KKSMultiACBulkC
        variable                = 'eta1'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cA1 cA2'
        eta_i                   = 'eta1'
        coupled_variables       = 'cB1 cB2 cC1 cC2 eta2 temp'
        mob_name                = 'L'
    []

    [ACBulkC1B]
        type                    = KKSMultiACBulkC
        variable                = 'eta1'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cB1 cB2'
        eta_i                   = 'eta1'
        coupled_variables       = 'cC1 cC2 cA1 cA2 eta2 temp'
        mob_name                = 'L'
    []

    [ACBulkC1C]
        type                    = KKSMultiACBulkC
        variable                = 'eta1'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cC1 cC2'
        eta_i                   = 'eta1'
        coupled_variables       = 'cA1 cA2 cB1 cB2 eta2 temp'
        mob_name                = 'L'
    []

    [ACInterface1]
        type                    = ACInterface
        variable                = 'eta1'
        kappa_name              = 'kappa'
        mob_name                = 'L'
    []

    [ACdfintdeta1]
        type                    = ACGrGrMulti
        variable                = 'eta1'
        v                       = 'eta2'
        gamma_names             = '${gamma}'
        mob_name                = 'L'
        coupled_variables       = 'eta2 temp'
    []

    # Kernels for Allen-Cahn equation for eta2

    [deta2dt]
        type                    = TimeDerivative
        variable                = 'eta2'
    []

    [ACBulkF2]
        type                    = KKSMultiACBulkF
        variable                = 'eta2'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        gi_name                 = 'g2'
        eta_i                   = 'eta2'
        wi                      = 5e-3
        coupled_variables       = 'cA1 cA2 cB1 cB2 cC1 cC2 eta1 temp'
        mob_name                = 'L'
    []

    [ACBulkC2A]
        type                    = KKSMultiACBulkC
        variable                = 'eta2'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cA1 cA2'
        eta_i                   = 'eta2'
        coupled_variables       = 'cB1 cB2 cC1 cC2 eta1 temp'
        mob_name                = 'L'
    []

    [ACBulkC2B]
        type                    = KKSMultiACBulkC
        variable                = 'eta2'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cB1 cB2'
        eta_i                   = 'eta2'
        coupled_variables       = 'cC1 cC2 cA1 cA2 eta1 temp'
        mob_name                = 'L'
    []

    [ACBulkC2C]
        type                    = KKSMultiACBulkC
        variable                = 'eta2'
        Fj_names                = 'F1 F2'
        hj_names                = 'h1 h2'
        cj_names                = 'cC1 cC2'
        eta_i                   = 'eta2'
        coupled_variables       = 'cA1 cA2 cB1 cB2 eta1 temp'
        mob_name                = 'L'
    []

    [ACInterface2]
        type                    = ACInterface
        variable                = 'eta2'
        kappa_name              = 'kappa'
        mob_name                = 'L'
    []

    [ACdfintdeta2]
        type                    = ACGrGrMulti
        variable                = 'eta2'
        v                       = 'eta1'
        gamma_names             = '${gamma}'
        mob_name                = 'L'
        coupled_variables       = 'eta1 temp'
    []
[]


[AuxVariables]
    [cD]
        order   = FIRST
        family  = LAGRANGE
    []

    [Energy]
        order   = CONSTANT
        family  = MONOMIAL
    []

    [bnds]
    []

    [gr_cA]
        order   = CONSTANT
        family  = MONOMIAL
    []

    [gr_cB]
        order   = CONSTANT
        family  = MONOMIAL
    []

    [gr_cC]
        order   = CONSTANT
        family  = MONOMIAL
    []
[]




[AuxKernels]
    [cD]
        type                = ParsedAux
        variable            = 'cD'
        coupled_variables   = 'cA cB cC'
        expression          = '1 - cA - cB - cC'
        execute_on          = 'TIMESTEP_END'
    []

    [Energy_total]
        type                = KKSMultiFreeEnergy
        Fj_names            = 'F1 F2'
        hj_names            = 'h1 h2'
        gj_names            = 'g1 g2'
        variable            = 'Energy'
        w                   = 1
        interfacial_vars    = 'eta1 eta2'
        kappa_names         = 'kappa kappa'
    []

    [bnds]
        type                = BndsCalcAux
        variable            = 'bnds'
        var_name_base       = 'eta'
        op_num              = 2
        v                   = 'eta1 eta2'
    []

    [sumCAdothsquare]
        type                = PhaseGlobalComposition
        variable            = 'gr_cA'
        global_composition  = 'cA'
        total_etas          = 2
        h_names             = 'h1 h2'
    []

    [sumCBdothsquare]
        type                = PhaseGlobalComposition
        variable            = 'gr_cB'
        global_composition  = 'cB'
        total_etas          = 2
        h_names             = 'h1 h2'
    []

    [sumCCdothsquare]
        type                = PhaseGlobalComposition
        variable            = 'gr_cC'
        global_composition  = 'cC'
        total_etas          = 2
        h_names             = 'h1 h2'
    []
[]

[Executioner]
    type                    = Transient
    solve_type              = 'PJFNK'
    automatic_scaling       = true

    # compute_scaling_once    = false
    # # resid_vs_jac_scaling_param = 0.25
    # scaling_group_variables = 'wA wB wC; cA cB cC; cA1 cA2; cB1 cB2; cC1 cC2; eta1 eta2'
    
    # https://mooseframework.inl.gov/modules/phase_field/Solving.html

    petsc_options           = '-snes_converged_reason -ksp_converged_reason -options_left'
    petsc_options_iname     = '-ksp_gmres_restart -pc_factor_shift_type -pc_factor_shift_amount -pc_type'
    petsc_options_value     = '100 NONZERO 1e-15 ilu'
    
    # petsc_options_iname     = '-pc_type -ksp_grmres_restart -sub_ksp_type -sub_pc_type -pc_asm_overlap'
    # petsc_options_value     = 'asm      31      preonly     lu      2'

    # petsc_options_iname     = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
    # petsc_options_value     = 'hypre    boomeramg      31       0.7'

    # petsc_options_iname     = '-pc_type -sub_pc_type   -sub_pc_factor_shift_type'
    # petsc_options_value     = 'asm       ilu            nonzero'


    l_max_its               = 30
    nl_max_its              = 50
    l_tol                   = 1e-04
    nl_rel_tol              = 1e-08
    nl_abs_tol              = 1e-09

    end_time                = ${end_time}
    # num_steps               = 20
    # dt                      = ${dt}

    dtmax                   = 2

    # [Adaptivity]
    #     initial_adaptivity  = 5
    #     refine_fraction     = 0.9
    #     coarsen_fraction    = 0.1
    #     max_h_level         = 2
    #     weight_names        = 'eta1 eta2'
    #     weight_values       = '1     1'
    # []

    [TimeStepper]
        type                = IterationAdaptiveDT
        dt                  = ${dt}
        cutback_factor      = 0.8
        growth_factor       = 1.5 
        optimal_iterations  = 7
        # num_steps           = 20
        # end_time            = 28
    []
[]


[Adaptivity]
    marker          = 'marker'
    initial_marker  = 'marker'
    initial_steps   = '2'
    max_h_level     = '2'
    # stop_time       = '0'
    [Markers]
        [marker]
            type                = OrientedBoxMarker
            center              = '500 230 0'
            length              = '1000'
            width               = '60'
            height              = '0'
            inside              = 'REFINE'
            outside             = 'DO_NOTHING'
            length_direction    = '1  0  0'
            width_direction     = '0  1  0'
        []
    []
[]

[Preconditioning]
    [SMP]
        type                = SMP
        full                = true
        # petsc_options_iname = '-pc_type -pc_factor_shift_type -pc_factor_mat_solver_type'
        # petsc_options_value = 'lu       NONZERO               strumpack'
    []

    active                  = 'SMP'

    [mydebug]
        type                = FDP
        full                = true
    []
[]


[Postprocessors]
    # Area of Phases
   [area_h1]
       type                 = ElementIntegralMaterialProperty
       mat_prop             = h1
       execute_on           = 'Initial TIMESTEP_END'
   []

    [area_h2]
        type                = ElementIntegralMaterialProperty
        mat_prop            = h2
        execute_on          = 'Initial TIMESTEP_END'
    []

    [dt]
        type                = TimestepSize
    []

    [temp_max]
        type                = ElementExtremeValue
        variable            = 'temp'
        value_type          = 'max'
    []

    [temp_avg]
        type                = ElementAverageValue
        variable            = 'temp'
    []

    [temp_min]
        type                = ElementExtremeValue
        variable            = 'temp'
        value_type          = 'min'
    []
[]


[Outputs]
    exodus                  = true
    time_step_interval      = 1
    file_base               = 'exodus/CoCrFeNi'
    csv                     = true
    [my_checkpoint]
        type                = Checkpoint
        num_files           = 2
        time_step_interval  = 2
        file_base           = 'exodus/CoCrFeNi'
    []
[]

 
[Debug]
    show_var_residual_norms = true
[]