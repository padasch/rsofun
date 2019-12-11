module sofun_r_mod
  !////////////////////////////////////////////////////////////////
  ! Contains main subroutine handling I/O with C and R.
  !----------------------------------------------------------------
  use, intrinsic :: iso_c_binding, only: c_double, c_int, c_char, c_bool

  implicit none

  private
  public :: sofun_f

contains

  subroutine sofun_f(          &
    spinup,                    &   
    spinupyears,               &        
    recycle,                   &    
    firstyeartrend,            &           
    nyeartrend,                &       
    soilmstress,               &        
    tempstress,                &       
    in_ppfd,                   &    
    in_netrad,                 &      
    const_clim_year,           &            
    const_lu_year,             &          
    const_co2_year,            &           
    const_ndep_year,           &            
    const_nfert_year,          &             
    ! daily_out_startyr,         &              
    ! daily_out_endyr,           &            
    outdt,                     &  
    ltre,                      & 
    ltne,                      & 
    ltrd,                      & 
    ltnd,                      & 
    lgr3,                      & 
    lgn3,                      & 
    lgr4,                      & 
    ! loutplant,                 &      
    ! loutgpp,                   &    
    ! loutwaterbal,              &         
    ! loutforcing,               &        
    ! loutdgpp,                  &     
    ! loutdrd,                   &    
    ! loutdtransp,               &        
    ! loutdwcont,                &       
    ! loutdaet,                  &     
    ! loutdpet,                  &     
    ! loutdnetrad,               &        
    ! loutdwbal,                 &      
    ! loutdtemp,                 &      
    ! loutdfapar,                &       
    ! loutdtemp_soil,            &           
    ! lcalibgpp,                 &      
    ! lcalibfapar,               &        
    ! lcalibtransp,              &         
    ! lcaliblatenth,             &          
    longitude,                 &      
    latitude,                  &     
    altitude,                  &     
    whc,                       &
    soiltexture,               &
    nt,                        &
    par,                       &
    forcing,                   &
    output                     &
    ) bind(C, name = "sofun_f_")

    !////////////////////////////////////////////////////////////////
    ! Main subroutine to handle I/O with C and R. 
    ! Receives simulation parameters, site parameters, and the full 
    ! simulation's forcing as time series
    !----------------------------------------------------------------
    use md_params_siml, only: getsteering
    use md_grid, only: get_domaininfo, getgrid, type_params_domain
    use md_params_soil, only: getsoil
    use md_forcing, only: getclimate, getco2, getfapar, get_fpc_grid
    use md_interface, only: interfacetype_biosphere, outtype_biosphere, myinterface
    use md_params_core, only: nlayers_soil, ndayyear, npft
    use md_biosphere, only: biosphere_annual

    implicit none

    ! arguments
    logical(kind=c_bool), intent(in) :: spinup
    integer(kind=c_int),  intent(in) :: spinupyears
    integer(kind=c_int),  intent(in) :: recycle
    integer(kind=c_int),  intent(in) :: firstyeartrend
    integer(kind=c_int),  intent(in) :: nyeartrend
    logical(kind=c_bool), intent(in) :: soilmstress
    logical(kind=c_bool), intent(in) :: tempstress
    logical(kind=c_bool), intent(in) :: in_ppfd
    logical(kind=c_bool), intent(in) :: in_netrad
    integer(kind=c_int),  intent(in) :: const_clim_year
    integer(kind=c_int),  intent(in) :: const_lu_year
    integer(kind=c_int),  intent(in) :: const_co2_year
    integer(kind=c_int),  intent(in) :: const_ndep_year
    integer(kind=c_int),  intent(in) :: const_nfert_year
    ! integer(kind=c_int),  intent(in) :: daily_out_startyr
    ! integer(kind=c_int),  intent(in) :: daily_out_endyr
    integer(kind=c_int),  intent(in) :: outdt
    logical(kind=c_bool), intent(in) :: ltre
    logical(kind=c_bool), intent(in) :: ltne
    logical(kind=c_bool), intent(in) :: ltrd
    logical(kind=c_bool), intent(in) :: ltnd
    logical(kind=c_bool), intent(in) :: lgr3
    logical(kind=c_bool), intent(in) :: lgn3
    logical(kind=c_bool), intent(in) :: lgr4
    ! logical(kind=c_bool), intent(in) :: loutplant
    ! logical(kind=c_bool), intent(in) :: loutgpp
    ! logical(kind=c_bool), intent(in) :: loutwaterbal
    ! logical(kind=c_bool), intent(in) :: loutforcing
    ! logical(kind=c_bool), intent(in) :: loutdgpp
    ! logical(kind=c_bool), intent(in) :: loutdrd
    ! logical(kind=c_bool), intent(in) :: loutdtransp
    ! logical(kind=c_bool), intent(in) :: loutdwcont
    ! logical(kind=c_bool), intent(in) :: loutdaet
    ! logical(kind=c_bool), intent(in) :: loutdpet
    ! logical(kind=c_bool), intent(in) :: loutdnetrad
    ! logical(kind=c_bool), intent(in) :: loutdwbal
    ! logical(kind=c_bool), intent(in) :: loutdtemp
    ! logical(kind=c_bool), intent(in) :: loutdfapar
    ! logical(kind=c_bool), intent(in) :: loutdtemp_soil
    ! logical(kind=c_bool), intent(in) :: lcalibgpp
    ! logical(kind=c_bool), intent(in) :: lcalibfapar
    ! logical(kind=c_bool), intent(in) :: lcalibtransp
    ! logical(kind=c_bool), intent(in) :: lcaliblatenth
    real(kind=c_double),  intent(in) :: longitude
    real(kind=c_double),  intent(in) :: latitude
    real(kind=c_double),  intent(in) :: altitude
    real(kind=c_double),  intent(in) :: whc
    real(kind=c_double),  dimension(4,nlayers_soil), intent(in) :: soiltexture   ! soil texture (rows: sand, clay, organic, gravel; columns: layers from top)
    integer(kind=c_int),  intent(in) :: nt ! number of time steps
    real(kind=c_double),  dimension(6), intent(in) :: par  ! free (calibratable) model parameters
    real(kind=c_double),  dimension(nt,10), intent(in)  :: forcing  ! array containing all temporally varying forcing data (rows: time steps; columns: 1=air temperature, 2=rainfall, 3=vpd, 4=ppfd, 5=net radiation, 6=sunshine fraction, 7=snowfall, 8=co2, 9=N-deposition, 10=fapar) 
    real(kind=c_double),  dimension(nt,5), intent(out) :: output

    ! local variables
    type(outtype_biosphere) :: out_biosphere  ! holds all the output used for calculating the cost or maximum likelihood function 
    type(type_params_domain) :: params_domain
    integer :: npft_local, yr, ncells, idx_start, idx_end

    !----------------------------------------------------------------
    ! GET SIMULATION PARAMETERS
    !----------------------------------------------------------------
    myinterface%params_siml%do_spinup        = spinup
    myinterface%params_siml%spinupyears      = spinupyears
    myinterface%params_siml%recycle          = recycle
    myinterface%params_siml%firstyeartrend   = firstyeartrend
    myinterface%params_siml%nyeartrend       = nyeartrend

    if (myinterface%params_siml%do_spinup) then
      myinterface%params_siml%runyears = myinterface%params_siml%nyeartrend + myinterface%params_siml%spinupyears
    else
      myinterface%params_siml%runyears = myinterface%params_siml%nyeartrend
      myinterface%params_siml%spinupyears = 0
    endif

    myinterface%params_siml%soilmstress      = soilmstress
    myinterface%params_siml%tempstress       = tempstress
    myinterface%params_siml%in_ppfd          = in_ppfd
    myinterface%params_siml%in_netrad        = in_netrad
    myinterface%params_siml%const_clim_year  = const_clim_year
    myinterface%params_siml%const_lu_year    = const_lu_year
    myinterface%params_siml%const_co2_year   = const_co2_year
    myinterface%params_siml%const_ndep_year  = const_ndep_year
    myinterface%params_siml%const_nfert_year = const_nfert_year
    ! myinterface%params_siml%daily_out_startyr= daily_out_startyr
    ! myinterface%params_siml%daily_out_endyr  = daily_out_endyr
    myinterface%params_siml%outdt            = outdt
    myinterface%params_siml%ltre             = ltre
    myinterface%params_siml%ltne             = ltne
    myinterface%params_siml%ltrd             = ltrd
    myinterface%params_siml%ltnd             = ltnd
    myinterface%params_siml%lgr3             = lgr3
    myinterface%params_siml%lgn3             = lgn3
    myinterface%params_siml%lgr4             = lgr4

    npft_local = 0
    if (myinterface%params_siml%ltre) npft_local = npft_local + 1
    if (myinterface%params_siml%ltne) npft_local = npft_local + 1
    if (myinterface%params_siml%ltrd) npft_local = npft_local + 1
    if (myinterface%params_siml%ltnd) npft_local = npft_local + 1
    if (myinterface%params_siml%lgr3) npft_local = npft_local + 1
    if (myinterface%params_siml%lgr4) npft_local = npft_local + 1
    if (myinterface%params_siml%lgn3) npft_local = npft_local + 1

    ! myinterface%params_siml%loutplant        = loutplant
    ! myinterface%params_siml%loutgpp          = loutgpp
    ! myinterface%params_siml%loutwaterbal     = loutwaterbal
    ! myinterface%params_siml%loutforcing      = loutforcing
    ! myinterface%params_siml%loutdgpp         = loutdgpp
    ! myinterface%params_siml%loutdrd          = loutdrd
    ! myinterface%params_siml%loutdtransp      = loutdtransp
    ! myinterface%params_siml%loutdwcont       = loutdwcont
    ! myinterface%params_siml%loutdaet         = loutdaet
    ! myinterface%params_siml%loutdpet         = loutdpet
    ! myinterface%params_siml%loutdnetrad      = loutdnetrad
    ! myinterface%params_siml%loutdwbal        = loutdwbal
    ! myinterface%params_siml%loutdtemp        = loutdtemp
    ! myinterface%params_siml%loutdfapar       = loutdfapar
    ! myinterface%params_siml%loutdtemp_soil   = loutdtemp_soil
    ! myinterface%params_siml%lcalibgpp        = lcalibgpp
    ! myinterface%params_siml%lcalibfapar      = lcalibfapar
    ! myinterface%params_siml%lcalibtransp     = lcalibtransp
    ! myinterface%params_siml%lcaliblatenth    = lcaliblatenth

    ! set parameter to define that this is not a calibration run (otherwise sofun.f90 would not have been compiled, but sofun_simsuite.f90)
    myinterface%params_siml%is_calib = .true.  ! treat paramters passed through R/C-interface the same way as calibratable parameters

    !----------------------------------------------------------------
    ! GET GRID INFORMATION
    !----------------------------------------------------------------
    ! below is done by getpar_domain() otherwise
    params_domain%lon_site      = real( longitude )
    params_domain%lat_site      = real( latitude )
    params_domain%elv_site      = real( altitude )
    params_domain%whc_site      = real( whc )

    myinterface%domaininfo = get_domaininfo( params_domain )

    ! allocate variable size arrays
    ! ncells = myinterface%domaininfo%maxgrid
    ncells = 1
    if (.not. allocated(myinterface%grid))         allocate( myinterface%grid(                       ncells ) )
    if (.not. allocated(myinterface%climate))      allocate( myinterface%climate(                    ncells ) )
    if (.not. allocated(myinterface%soilparams))   allocate( myinterface%soilparams(   nlayers_soil, ncells ) )
    if (.not. allocated(myinterface%dfapar_field)) allocate( myinterface%dfapar_field( ndayyear,     ncells ) )
    if (.not. allocated(myinterface%fpc_grid))     allocate( myinterface%fpc_grid(     npft,         ncells ) )
    ! allocate( myinterface%ninput_field(               ncells ) )
    ! allocate( myinterface%landuse(                    ncells ) )

    ! vectorise 2D array, keeping only land gridcells
    myinterface%grid(:) = getgrid( myinterface%domaininfo, params_domain )

    !----------------------------------------------------------------
    ! GET SOIL PARAMETERS
    !----------------------------------------------------------------
    myinterface%soilparams(:,:) = getsoil( soiltexture )

    ! Overwrite whc
    myinterface%soilparams(:,:)%whc = whc

    !----------------------------------------------------------------
    ! GET CALIBRATABLE MODEL PARAMETERS (so far a small list)
    !----------------------------------------------------------------
    ! XXX warning: converting from double to single may cause a problem
    ! when calibrating and parameters are varied in their Nth digit after
    ! the comma!  
    myinterface%params_calib%kphio           = real(par(1))
    myinterface%params_calib%soilm_par_a     = real(par(2))
    myinterface%params_calib%soilm_par_b     = real(par(3))
    myinterface%params_calib%vpdstress_par_a = real(par(4))
    myinterface%params_calib%vpdstress_par_b = real(par(5))
    myinterface%params_calib%vpdstress_par_m = real(par(6))

    !----------------------------------------------------------------
    ! GET VEGETATION COVER (fractional projective cover by PFT)
    !----------------------------------------------------------------
    myinterface%fpc_grid(:,:) = get_fpc_grid( myinterface%domaininfo, myinterface%params_siml )


    ! LOOP THROUGH YEARS
    ! print*, '-------------------START OF SIMULATION--------------------'


    do yr=1,myinterface%params_siml%runyears

      !----------------------------------------------------------------
      ! Define simulations "steering" variables (forcingyear, etc.)
      !----------------------------------------------------------------
      myinterface%steering = getsteering( yr, myinterface%params_siml )

      ! if (yr == myinterface%params_siml%spinupyears+1 ) then
      !   print*, '------------------TRANSIENT SIMULATION--------------------'
      ! endif


      !----------------------------------------------------------------
      ! Get external (environmental) forcing
      !----------------------------------------------------------------
      ! Get climate variables for this year (full fields and 365 daily values for each variable)
      myinterface%climate(:) = getclimate(  &
                                            nt, &
                                            forcing, &
                                            myinterface%domaininfo, &
                                            myinterface%grid, &
                                            myinterface%steering%init, &
                                            myinterface%steering%climateyear_idx, &
                                            myinterface%params_siml%in_ppfd,  &
                                            myinterface%params_siml%in_netrad &
                                            )

      ! Get annual, gobally uniform CO2
      myinterface%pco2 = getco2(  &
                                  nt, &
                                  forcing, &
                                  myinterface%domaininfo, &
                                  myinterface%steering%forcingyear, &
                                  myinterface%params_siml%const_co2_year, &
                                  myinterface%params_siml%firstyeartrend &
                                  )

      ! ! Atmospheric N deposition (note that actual data is not read in all SOFUN setups)
      ! ndep_field(:) = getninput( &
      !   "ndep", &
      !   trim(runname), &
      !   myinterface%domaininfo, &
      !   myinterface%steering%forcingyear, &
      !   myinterface%params_siml%firstyeartrend, &
      !   myinterface%params_siml%const_ndep_year, &
      !   myinterface%params_siml%ndep_noy_forcing_file, &
      !   myinterface%params_siml%ndep_nhx_forcing_file, &
      !   myinterface%climate(:)&
      !   )
      
      ! ! N fertiliser input (note that actual data is not read in all SOFUN setups)
      ! nfert_field(:) = getninput( &
      !   "nfert", &
      !   trim(runname), &
      !   myinterface%domaininfo, &
      !   myinterface%steering%forcingyear, &
      !   myinterface%params_siml%firstyeartrend, &
      !   myinterface%params_siml%const_nfert_year, &
      !   myinterface%params_siml%nfert_noy_forcing_file, &
      !   myinterface%params_siml%nfert_nhx_forcing_file, &
      !   myinterface%climate(:)&
      !   )

      ! ! myInterface holds only total reactive N input (N deposition + N fertiliser)                             
      ! myinterface%ninput_field(:) = gettot_ninput( nfert_field(:), ndep_field(:) )
                                   
      ! ! Get land use information (note that actual data is not read in all SOFUN setups)
      ! myinterface%landuse(:) = getlanduse( &
      !   trim(runname), &
      !   myinterface%domaininfo, &
      !   myinterface%steering%forcingyear, &
      !   myinterface%params_siml%do_grharvest_forcing_file, &
      !   myinterface%params_siml%const_lu_year, &
      !   myinterface%params_siml%firstyeartrend &
      !   )

      !----------------------------------------------------------------
      ! Get prescribed fAPAR if required (otherwise set to dummy value)
      !----------------------------------------------------------------
      myinterface%dfapar_field(:,:) = getfapar( &
                                                nt, &
                                                forcing, &
                                                myinterface%domaininfo, &
                                                myinterface%grid, &
                                                myinterface%steering%forcingyear_idx &
                                                )    

      !----------------------------------------------------------------
      ! Call SR biosphere at an annual time step but with vectors 
      ! containing data for each day of this year.
      !----------------------------------------------------------------
      ! print*,'--------------------------------------------------------'
      ! print*,'Simulation year: ', myinterface%steering%year, ' - Real year: ', myinterface%steering%outyear
      ! print*,'--------------------------------------------------------'
      
      !----------------------------------------------------------------
      ! Call biosphere (wrapper for all modules, contains gridcell loop)
      !----------------------------------------------------------------
      out_biosphere = biosphere_annual() 
      !----------------------------------------------------------------

      !----------------------------------------------------------------
      ! Populate Fortran output array which is passed back to C/R
      !----------------------------------------------------------------
      if (yr > myinterface%params_siml%spinupyears ) then

        idx_start = (myinterface%steering%forcingyear_idx - 1) * ndayyear + 1
        idx_end   = idx_start + ndayyear - 1

        output(idx_start:idx_end,1) = dble(out_biosphere%fapar(:))  
        output(idx_start:idx_end,2) = dble(out_biosphere%gpp(:))    
        output(idx_start:idx_end,3) = dble(out_biosphere%transp(:)) 
        output(idx_start:idx_end,4) = dble(out_biosphere%latenth(:))
        output(idx_start:idx_end,5) = 0.d0

      end if

    enddo

    ! print*, '--------------------END OF SIMULATION---------------------'

    ! clean up
    deallocate(myinterface%grid)
    deallocate(myinterface%climate)
    deallocate(myinterface%soilparams)
    deallocate(myinterface%dfapar_field)

  end subroutine sofun_f

end module sofun_r_mod
