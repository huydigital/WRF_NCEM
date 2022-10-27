#!/bin/bash

set -e
set -u

scriptdir=`pwd`
WRFLIB=/home/toandk/Build_WRF/LIBRARIES
GFSDIR=${scriptdir}/GFS
WRFOUTDIR=${scriptdir}/WRF_OUT


#fcdate=20220809
WRFpp=true
RunWRF=true

#
#
# Get WRF boundaries
#
GFSDATE=`date -u -d "$fcdate -1 day" +"%Y%m%d"`
GFSHH=12
GFSHOURS=60
GFSPREF=ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${GFSDATE}/${GFSHH}/atmos
GFSFCDIR=$GFSDIR/$GFSDATE$GFSHH
mkdir -p $GFSFCDIR
cd $GFSFCDIR
for fff in `seq -f %03.0f 0 3 $GFSHOURS`; do
	fname=gfs.t${GFSHH}z.pgrb2.0p50.f$fff
	[ -f $fname ] ||  echo "wget $GFSPREF/${fname} -O ${fname}.tmp && mv ${fname}.tmp ${fname}"
done |xargs -P 8 -IXXX -r -t sh -c "XXX"


start_date=`date -u -d "$GFSDATE $GFSHH" +"%Y-%m-%d_%H:00:00"`
end_date=`date -u -d "$GFSHOURS hours $GFSHH hours $GFSDATE" +"%Y-%m-%d_%H:00:00"`
#/home/toandk/Build_WRF/LIBRARIES//WPS-4.1/namelist.wps

if $WRFpp; then
	linkgrib=${WRFLIB}/WPS-4.1/link_grib.csh
	ungrib=${WRFLIB}/WPS-4.1/ungrib.exe
	metgrid=${WRFLIB}/WPS-4.1/metgrid.exe
	Vtable=${WRFLIB}/WPS-4.1/Vtable
	METGRIDTBL=${WRFLIB}/WPS-4.1/METGRID.TBL
	$linkgrib ./gfs.t
	cat > namelist.wps <<EOF
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '$start_date',
 end_date   = '$end_date',
 interval_seconds = 10800,
 debug_level = 1,
 io_form_geogrid = 2,
/

&geogrid
 parent_id         =   1, 
 parent_grid_ratio =   1,  
 i_parent_start    =   1,   
 j_parent_start    =   1, 
 e_we              =  100, 
 e_sn              =  100, 
 geog_data_res = 'default',
 dx = 36000, 
 dy = 36000,
 map_proj = 'lambert',
 ref_lat   =  21.207,
 ref_lon   = 105.66,
 truelat1  =  21.207,
 truelat2  =  10.207,
 stand_lon = 105.66,
 geog_data_path = '/home/toandk/Build_WRF/LIBRARIES/WPS_GEOG/'
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE',
 io_form_metgrid = 2, 
/
EOF

	echo "Ungribbing"
	ln -sf $Vtable ./

	##Ungrib
	$ungrib
	echo Done $ungrib
	  
	  echo "Running $metgrid in `pwd`"
	ls $METGRIDTBL
	mkdir -p metgrid
	ln -sf $METGRIDTBL ./metgrid/
	ln -sf ${WRFLIB}/WPS-4.1/geo_em.d01.nc ./
	$metgrid
	echo Done pre-processing
fi




#
#
#  Actual WRF run
#
#
if $RunWRF; then
	realbin=${WRFLIB}/WRF-4.1.2bis/main/real.exe
	wrfbin=${WRFLIB}/WRF-4.1.2bis/main/wrf.exe
	
	wrfrun=${WRFLIB}/WRF-4.1.2bis/run
	ln -sf $wrfrun/*.TBL $wrfrun/ozone* $wrfrun/RRTM* ./
	

	YY1=`date -u -d "$GFSDATE $GFSHH" +"%Y"`
	MM1=`date -u -d "$GFSDATE $GFSHH" +"%m"`
	DD1=`date -u -d "$GFSDATE $GFSHH" +"%d"`
	HH1=$GFSHH
	YY2=`date -u -d "$GFSHOURS hours $GFSHH hours $GFSDATE" +"%Y"`
	MM2=`date -u -d "$GFSHOURS hours $GFSHH hours $GFSDATE" +"%m"`
	DD2=`date -u -d "$GFSHOURS hours $GFSHH hours $GFSDATE" +"%d"`
	HH2=`date -u -d "$GFSHOURS hours $GFSHH hours $GFSDATE" +"%H"`
	cat >namelist.input <<EOF
 &time_control
 run_days                            = 0,
 run_hours                           = 0,
 run_minutes                         = 0,
 run_seconds                         = 0,
 start_year                          = $YY1, 2022, 2022,
 start_month                         = $MM1,   01,   01,
 start_day                           = $DD1,   27,   27,
 start_hour                          = $HH1,   00,   00,
 start_minute                        = 00,   00,   00,
 start_second                        = 00,   00,   00,
 end_year                            = $YY2, 2022, 2022,
 end_month                           = $MM2,   01,   01,
 end_day                             = $DD2,   31,   31,
 end_hour                            = $HH2,   00,   00,
 end_minute                          = 00,   00,   00,
 end_second                          = 00,   00,   00,
 interval_seconds                    = 10800                    
 input_from_file                     = .true.,.true.,.true.,    
 history_interval                    = 60,  60,   60,           
 frames_per_outfile                  = 1, 1, 1,
 restart                             = .false.,                 
 restart_interval                    = 5000,                    
 io_form_history                     = 2                        
 io_form_restart                     = 2                        
 io_form_input                       = 2                        
 io_form_boundary                    = 2                        
 debug_level                         = 0                        
 /                                                              
                                                                
 &domains                                                       
 time_step                           = 60,                     
 time_step_fract_num                 = 0,                       
 time_step_fract_den                 = 1,                       
 max_dom                             = 1,                       
 e_we                                = 100,    124,   94,       
 e_sn                                = 100,    208,    91,      
 e_vert                              = 40,    40,    40,        
 p_top_requested                     = 5000,                    
 num_metgrid_levels                  = 34,                      
 num_metgrid_soil_levels             = 4,                       
 dx                                  = 36000, 9000,  3333.33,   
 dy                                  = 36000, 9000,  3333.33,   
 grid_id                             = 1,     2,     3,         
 parent_id                           = 0,     1,     2,         
 i_parent_start                      = 0,     34,    30,        
 j_parent_start                      = 0,     17,    30,        
 parent_grid_ratio                   = 1,     3,     3,         
 parent_time_step_ratio              = 1,     3,     3,         
 feedback                            = 1,                       
 smooth_option                       = 0                        
 /                                                              
                                                                
 &physics                                                       
 mp_physics                          = 7,     7,     3,         
 ra_lw_physics                       = 4,     4,     4,         
 ra_sw_physics                       = 4,     4,     4,         
 radt                                = 30,    30,    30,        
 sf_sfclay_physics                   = 1,     1,     1,         
 sf_surface_physics                  = 2,     2,     2,         
 bl_pbl_physics                      = 1,     1,     1,   
 bldt                                = 0,     0,     0,
 cu_physics                          = 1,     1,     0,         
 cudt                                = 5,     5,     5,         
 kfeta_trigger                       = 2,
 isfflx                              = 1,                       
 ifsnow                              = 0,                       
 icloud                              = 1,                       
 surface_input_source                = 1,                      
 num_land_cat                        = 21, 
 num_soil_layers                     = 4,                       
 sf_urban_physics                    = 0,     0,     0,                             
 /                                                              
                                                                
 &fdda                                                          
 /                                                              
                                                                
 &dynamics                                                      
 w_damping                           = 0,                       
 diff_opt                            = 1,                       
 km_opt                              = 4,                       
 diff_6th_opt                        = 0,      0,      0,       
 diff_6th_factor                     = 0.12,   0.12,   0.12,    
 base_temp                           = 290.                     
 damp_opt                            = 0,                       
 zdamp                               = 5000.,  5000.,  5000.,   
 dampcoef                            = 0.2,    0.2,    0.2      
 khdif                               = 0,      0,      0,       
 kvdif                               = 0,      0,      0,       
 non_hydrostatic                     = .true., .true., .true.,  
 moist_adv_opt                       = 1,      1,      1,       
 scalar_adv_opt                      = 1,      1,      1,       
 /                                                              
                                                                
 &bdy_control                                                   
 spec_bdy_width                      = 5,                       
 spec_zone                           = 1,                       
 relax_zone                          = 4,                       
 specified                           = .true., .false.,.false., 
 nested                              = .false., .true., .true., 
 /                                                              
                                                                
 &grib2                                                         
 /                                                              
                                                                
 &namelist_quilt                                                
 nio_tasks_per_group = 0,                                       
 nio_groups = 1,                                                
 /                                                              
EOF
	date
	echo Running $realbin
	/usr/bin/mpirun.mpich  -n `nproc` $realbin
	date
	echo Running $wrfbin
	/usr/bin/mpirun.mpich  -n `nproc` $wrfbin
	date
	echo Done with WRF
	WRFFCDIR=$WRFOUTDIR/$GFSDATE$GFSHH
	mkdir -p $WRFFCDIR
	mv wrfout_* $WRFFCDIR
	date
fi



#./downloadGFS24hToday50.sh
#./downloadGFS24hToday500.sh
#cd /home/toandk/Build_WRF/LIBRARIES/WPS-4.1
#vi namelist.wps
#date 

