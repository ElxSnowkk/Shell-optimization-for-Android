#!/system/bin/sh

clear
echo ""
echo "#######################################################"
echo "##           ANDROID ULTIMATE OPTIMIZER v12          ##"
echo "##         Complete All-in-One Optimization System   ##"
echo "#######################################################"
echo ""

# Settings
LOG_FILE="/sdcard/AndroidOptimizer.log"
PROTECTED_APPS="
# Essential Google Services
com.google.android.gms
com.google.android.gsf
com.android.vending
com.google.android.syncadapters.contacts
com.google.android.backuptransport
com.google.android.onetimeinitializer
com.google.android.partnersetup

# Communication
com.whatsapp
com.instagram.android
com.facebook.katana
com.facebook.orca
org.telegram.messenger
com.signal
com.discord

# Banking/Finance
com.bankinter.launcher
com.lacaixa.mobile.android.newwapicon
com.bbva.bbvacontigo
com.santander.app
com.paypal.android.p2pmobile

# Productivity
com.microsoft.office.word
com.dropbox.android
com.lastpass.lpandroid
com.termux

# Security
com.avast.android.mobilesecurity
com.bitdefender.security

# Transportation
com.ubercab
com.waze

# Google Apps
com.google.android.apps.maps
com.google.android.apps.photos
com.google.android.youtube
com.google.android.gm
com.google.android.tts
com.google.android.apps.docs
com.google.android.apps.translate
com.google.android.calendar
com.google.android.contacts
com.google.android.keep
com.google.android.apps.meetings
"

ROOT_AVAILABLE=false
if su -c "id" | grep -q "uid=0"; then
  ROOT_AVAILABLE=true
fi

# Report variables
OPTIMIZED_APPS=""
BLOAT_REMOVED=""
GAMES_OPTIMIZED=""
ERRORS_FOUND=""
ROOT_OPERATIONS=""
STORAGE_FREED=""
MEMORY_FREED=""
BACKGROUND_KILLED=""

# Logging function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Protected app check
is_protected() {
  echo "$PROTECTED_APPS" | grep -q "$1"
}

# 1. Advanced Storage Cleaning
clean_storage() {
  log "🧹 STARTING STORAGE CLEANING"
  
  # Temp cache cleaning
  cache_size=$(du -sh /data/local/tmp 2>/dev/null | cut -f1 || echo "0MB")
  rm -rf /data/local/tmp/* 2>/dev/null
  log " ✔ Temp cache cleared: ${cache_size:-0MB} freed"
  
  # Thumbnails cleaning
  thumb_size=$(du -sh /sdcard/DCIM/.thumbnails 2>/dev/null | cut -f1 || echo "0MB")
  rm -rf /sdcard/DCIM/.thumbnails/* 2>/dev/null
  log " ✔ Thumbnails cleared: ${thumb_size:-0MB} freed"
  
  # Temp files cleaning
  log_files=$(find /sdcard/ -name "*.log" -o -name "*.tmp" 2>/dev/null | wc -l)
  find /sdcard/ -name "*.log" -o -name "*.tmp" -delete 2>/dev/null
  log " ✔ Temp files removed: $log_files files"
  
  # Empty directories cleaning
  empty_dirs=$(find /sdcard/ -type d -empty 2>/dev/null | wc -l)
  find /sdcard/ -type d -empty -delete 2>/dev/null
  log " ✔ Empty directories removed: $empty_dirs dirs"
  
  # Storage calculation
  before_clean=$(df /sdcard 2>/dev/null | tail -1 | awk '{print $4}')
  sync
  after_clean=$(df /sdcard 2>/dev/null | tail -1 | awk '{print $4}')
  [ -z "$before_clean" ] && before_clean=0
  [ -z "$after_clean" ] && after_clean=0
  freed_space=$((after_clean - before_clean))
  STORAGE_FREED="${freed_space}KB"
  
  log "✅ STORAGE CLEANED - ${freed_space}KB freed"
}

# 2. RAM Memory Management
manage_memory() {
  log "🧠 OPTIMIZING RAM MEMORY"
  
  # Memory cache cleaning
  if $ROOT_AVAILABLE; then
    su -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    log " ✔ Memory cache cleared (root)"
  else
    sync
    log " ℹ️ Cache cleaning requires root"
  fi
  
  # Background processes killing
  background_count=0
  for pkg in $(pm list packages -3 | cut -d':' -f2); do
    if ! is_protected "$pkg"; then
      am force-stop "$pkg" >/dev/null 2>&1
      background_count=$((background_count + 1))
      BACKGROUND_KILLED="$BACKGROUND_KILLED$pkg\n"
    fi
  done
  log " ✔ Processes killed: $background_count apps"
  
  # Background process limit
  settings put global background_process_limit 3
  log " ✔ Background limit: 3 processes"
  
  # Memory status
  mem_info=$(free -m 2>/dev/null || echo "0 0 0 0")
  total_mem=$(echo "$mem_info" | awk 'NR==2{print $2}')
  free_mem=$(echo "$mem_info" | awk 'NR==2{print $4}')
  [ -z "$total_mem" ] && total_mem=0
  [ -z "$free_mem" ] && free_mem=0
  if [ "$total_mem" -gt 0 ]; then
    mem_percent=$((free_mem * 100 / total_mem))
    MEMORY_FREED="${free_mem}MB (${mem_percent}%)"
  else
    MEMORY_FREED="N/A"
  fi
  
  log "✅ MEMORY OPTIMIZED - ${free_mem}MB free"
}

# 3. Smart Cache Optimization
optimize_cache() {
  log "🔄 STARTING APP CACHE CLEANING"
  total_apps=0
  for pkg in $(pm list packages | cut -d':' -f2); do
    if ! is_protected "$pkg"; then
      app_name=$(dumpsys package "$pkg" | grep "application-label:" | head -1 | cut -d':' -f2 | tr -d ' ')
      [ -z "$app_name" ] && app_name="$pkg"
      
      cache_path=$(dumpsys package "$pkg" | grep "codePath=" | cut -d'=' -f2 | tr -d ' ')
      cache_size=""
      if [ -d "$cache_path" ]; then
        cache_size=$(du -sh "$cache_path" 2>/dev/null | cut -f1)
      fi
      
      if pm clear "$pkg" >/dev/null 2>&1; then
        OPTIMIZED_APPS="$OPTIMIZED_APPS$app_name (${cache_size:-?})\n"
        log " ✔ Cache cleared: $app_name (${cache_size:-?})"
      else
        ERRORS_FOUND="$ERRORS_FOUND$app_name (cache)\n"
        log " ✖ Failed to clear: $app_name"
      fi
      total_apps=$((total_apps + 1))
    fi
  done
  pm trim-caches 99999999999 2>/dev/null
  log "✅ CACHE CLEANING COMPLETE - $total_apps apps processed"
}

# 4. Advanced Bloatware Removal
debloat_system() {
  log "🗑️ STARTING BLOATWARE REMOVAL"
  bloat_list="
  # Bloat original
  com.facebook.system com.facebook.appmanager
  com.miui.analytics com.xiaomi.mipicks
  com.google.android.apps.turbo com.android.wallpaperbackup
  com.samsung.android.bixby.agent com.samsung.android.game.gos
  com.huawei.android.hwpay com.huawei.hwid
  com.oppo.oppopowermonitor com.oppo.engineermode
  com.vivo.browser com.vivo.assistant
  com.realme.wellbeing com.oneplus.brickmode

  # Nova lista de bloatware
  android.auto_generated_characteristics_rro
  android.auto_generated_rro_product__
  android.auto_generated_rro_vendor__
  com.android.apps.tag
  com.android.bips
  com.android.bookmarkprovider
  com.android.dreams.phototable
  com.android.hotwordenrollment.okgoogle
  com.android.hotwordenrollment.xgoogle
  com.android.internal.display.cutout.emulation.waterfall
  com.android.printspooler
  com.android.providers.calendar
  com.android.providers.partnerbookmarks
  com.android.role.notes.enabled
  com.android.settings.intelligence
  com.facebook.appmanager
  com.facebook.katana
  com.facebook.services
  com.facebook.system
  com.google.android.aicore
  com.google.android.apps.accessibility.voiceaccess
  com.google.android.apps.aiwallpapers
  com.google.android.apps.bard
  com.google.android.apps.docs
  com.google.android.apps.photos
  com.google.android.apps.restore
  com.google.android.apps.tachyon
  com.google.android.apps.youtube.music
  com.google.android.feedback
  com.google.android.gm
  com.google.android.gms.supervision
  com.google.android.googlequicksearchbox
  com.google.android.healthconnect.controller
  com.google.android.onetimeinitializer
  com.google.android.partnersetup
  com.google.android.printservice.recommendation
  com.google.android.projection.gearhead
  com.google.android.safetycenter.resources
  com.google.android.syncadapters.calendar
  com.google.android.tts
  com.google.android.videos
  com.google.android.youtube
  com.google.ar.core
  com.google.audio.hearing.visualization.accessibility.scribe
  com.google.mainline.telemetry
  com.linkedin.android
  com.microsoft.appmanager
  com.microsoft.office.officehubrow
  com.microsoft.office.outlook
  com.microsoft.skydrive
  com.monotype.android.font.samsungone
  com.netflix.mediaclient
  com.osp.app.signin
  com.samsung.android.aicore
  com.samsung.android.app.find
  com.samsung.android.app.interpreter
  com.samsung.android.app.notes
  com.samsung.android.app.omcagent
  com.samsung.android.app.parentalcare
  com.samsung.android.app.readingglass
  com.samsung.android.app.sketchbook
  com.samsung.android.app.spage
  com.samsung.android.app.tips
  com.samsung.android.app.updatecenter
  com.samsung.android.app.watchmanager
  com.samsung.android.aremoji
  com.samsung.android.aremojieditor
  com.samsung.android.authfw
  com.samsung.android.bixby.agent
  com.samsung.android.bixby.ondevice.enus
  com.samsung.android.bixby.ondevice.esus
  com.samsung.android.bixby.wakeup
  com.samsung.android.bixbyvision.framework
  com.samsung.android.carkey
  com.samsung.android.coldwalletservice
  com.samsung.android.da.daagent
  com.samsung.android.dbsc
  com.samsung.android.dkey
  com.samsung.android.ese
  com.samsung.android.fmm
  com.samsung.android.game.gamehome
  com.samsung.android.game.gametools
  com.samsung.android.game.gos
  com.samsung.android.globalpostprocmgr
  com.samsung.android.gru
  com.samsung.android.hwresourceshare.storage
  com.samsung.android.intellivoiceservice
  com.samsung.android.ipsgeofence
  com.samsung.android.kidsinstaller
  com.samsung.android.knox.zt.framework
  com.samsung.android.liveeffectservice
  com.samsung.android.mapsagent
  com.samsung.android.mdecservice
  com.samsung.android.mdx
  com.samsung.android.net.wifi.wifiguider
  com.samsung.android.nmt.apps.t2t.languagepack.enesus
  com.samsung.android.offline.languagemodel
  com.samsung.android.oneconnect
  com.samsung.android.samsungpass
  com.samsung.android.samsungpassautofill
  com.samsung.android.scloud
  com.samsung.android.scpm
  com.samsung.android.sdk.ocr
  com.samsung.android.service.peoplestripe
  com.samsung.android.service.stplatform
  com.samsung.android.service.tagservice
  com.samsung.android.smartmirroring
  com.samsung.android.smartsuggestions
  com.samsung.android.smartswitchassistant
  com.samsung.android.spay
  com.samsung.android.spayfw
  com.samsung.android.ssco
  com.samsung.android.stickercenter
  com.samsung.android.tvplus
  com.samsung.android.vision.model
  com.samsung.android.visionintelligence
  com.samsung.android.visual.cloudcore
  com.samsung.android.voc
  com.samsung.android.vtcamerasettings
  com.samsung.app.newtrim
  com.samsung.ecomm
  com.samsung.petservice
  com.samsung.SMT
  com.samsung.SMT.lang_en_us_l03
  com.samsung.SMT.lang_es_mx_f00
  com.samsung.SMT.lang_es_us_l01
  com.samsung.SMT.lang_pt_br_l01
  com.samsung.sree
  com.samsung.storyservice
  com.sec.android.app.billing
  com.sec.android.app.desktoplauncher
  com.sec.android.app.kidshome
  com.sec.android.app.magnifier
  com.sec.android.app.samsungapps
  com.sec.android.app.sbrowser
  com.sec.android.app.setupwizard
  com.sec.android.app.shealth
  com.sec.android.app.ve.vebgm
  com.sec.android.app.vepreload
  com.sec.android.app.voicenote
  com.sec.android.autodoodle.service
  com.sec.android.desktopmode.uiservice
  com.sec.android.dexsystemui
  com.sec.android.easyMover
  com.sec.android.easyonehand
  com.sec.android.mimage.avatarstickers
  com.sec.android.mimage.photoretouching
  com.sec.location.nsflp2
  com.sec.penup
  com.spotify.music
  com.google.android.marvin.talkback
  com.motorola.genie
  com.android.egg
  com.motorola.brapps
  com.sprd.providers.photos
  com.android.calllogbackup
  com.google.android.apps.wellbeing
  com.android.bluetoothmidiservice
  com.android.bookmarkprovider
  com.android.carrierdefaultapp
  com.android.carrierconfig
  com.android.cts.ctsshim
  com.android.emergency
  com.google.android.ondevicepersonalization.services
  com.android.phone.injection
  com.android.providers.partnerbookmarks
  com.android.providers.settings.auto_generated_rro_product__
  com.android.sharedstoragebackup
  com.android.wallpaperbackup
  com.android.wallpapercropper
  com.google.android.nearby.halfsheet
  com.google.android.overlay.modules.documentsui
  com.google.android.overlay.modules.permissioncontroller
  com.motorola.android.providers.chromehomepage
  com.sprd.srmi
  com.google.android.feedback
  com.google.android.gms.supervision
  com.motorola.motocit
  com.android.dreams.basic
  com.motorola.demo
  com.motorola.motocare
  android.autoinstalls.config.motorola.layout
  com.google.android.apps.turbo
  com.google.android.apps.docs
  com.google.android.apps.safetyhub
  com.google.android.apps.adm
  com.sprd.engineermode
  com.android.stk
  com.google.android.apps.nbu.files
  com.inmobi.installer
  com.android.companiondevicemanager
  com.motorola.ccc.devicemanagement
  com.google.android.apps.assistant
  com.google.android.onetimeinitializer
  com.google.android.partnersetup
  com.google.android.videos
  com.android.soundrecorder
  com.google.android.gms.location.history
  com.lenovo.lsf.user
  com.android.bips
  com.spreadtrum.proxy.nfwlocation
  com.google.android.apps.maps
  com.google.android.apps.tachyon
  com.facebook.system
  com.facebook.appmanager
  com.facebook.services
  com.dti.motorola
  com.motorola.bach.modemstats
  com.motorola.help
  com.motorola.timeweatherwidget
  com.aura.oobe.motorola
  com.motorola.motosignature.app
  com.google.android.apps.restore
  com.android.musicfx
  com.motorola.ccc.notification
  com.android.theme.font.notoserifsource
  com.google.android.hotspot2.osulogin
  com.motorola.ccc.mainplm
  com.google.android.printservice.recommendation
  com.android.cameraextensions
  com.android.fmradio
  com.android.traceur
  com.google.android.safetycenter.resources
  com.android.remoteprovisioner
  com.spreadtrum.sgps
  com.google.android.gmsintegration
  com.sprd.uasetting
  com.sprd.logmanager
  com.google.android.apps.youtube.music
  "
  
  removed_count=0
  for pkg in $bloat_list; do
    [ -z "$pkg" ] && continue
    [[ "$pkg" == \#* ]] && continue
    
    if pm list packages | grep -q "$pkg"; then
      if ! is_protected "$pkg"; then
        if pm uninstall --user 0 "$pkg" >/dev/null 2>&1; then
          BLOAT_REMOVED="$BLOAT_REMOVED$pkg\n"
          log " ✔ Bloat removed: $pkg"
          removed_count=$((removed_count + 1))
        elif pm disable-user --user 0 "$pkg" >/dev/null 2>&1; then
          BLOAT_REMOVED="$BLOAT_REMOVED$pkg (disabled)\n"
          log " ✔ Bloat disabled: $pkg"
          removed_count=$((removed_count + 1))
        else
          ERRORS_FOUND="$ERRORS_FOUND$pkg (bloat)\n"
          log " ✖ Failed to remove: $pkg"
        fi
      else
        log " ℹ️ Protected app: $pkg (skipped)"
      fi
    fi
  done
  log "✅ DEBLOAT COMPLETE - $removed_count items processed"
}

# 5. Gaming Optimization
optimize_gaming() {
  log "🎮 STARTING GAMING OPTIMIZATION"
  games=$(pm list packages | cut -d':' -f2 | grep -Ei 'game|mlbb|cod|pubg|freefire|amongus|genshin|fortnite')
  
  if [ -n "$games" ]; then
    for game in $games; do
      game_name=$(dumpsys package "$game" | grep "application-label:" | head -1 | cut -d':' -f2 | tr -d ' ')
      [ -z "$game_name" ] && game_name="$game"
      
      pm grant "$game" android.permission.SYSTEM_ALERT_WINDOW 2>/dev/null
      appops set "$game" SYSTEM_ALERT_WINDOW allow 2>/dev/null
      
      if $ROOT_AVAILABLE; then
        pid=$(pidof "$game")
        if [ -n "$pid" ]; then
          su -c "echo -17 > /proc/$pid/oom_adj" 2>/dev/null
        fi
      fi
      
      GAMES_OPTIMIZED="$GAMES_OPTIMIZED$game_name\n"
      log " 🕹️ Game optimized: $game_name"
    done
    
    settings put global game_driver_all_apps 1 2>/dev/null
    settings put global game_driver_enabled 1 2>/dev/null
    settings put global force_gpu_rendering 1 2>/dev/null
    log " ✔ Gaming settings applied"
  else
    log " ℹ️ No games found"
  fi
  log "✅ GAMING OPTIMIZATION COMPLETE"
}

# 6. System Tweaks
system_tweaks() {
  log "⚙️ APPLYING SYSTEM TWEAKS"
  
  # Performance improvements
  settings put global window_animation_scale 0.4
  settings put global transition_animation_scale 0.4
  settings put global animator_duration_scale 0.4
  
  # Memory improvements
  settings put global app_standby_enabled 1
  settings put global app_ops_standby 1
  settings put global memc_opt_enable 1
  settings put global background_process_limit 4
  
  # Network and background
  cmd netpolicy set restrict-background true 2>/dev/null
  settings put global restricted_device_performance 1
  settings put global restrict_background_network 1
  
  # Battery saving
  settings put global adaptive_battery_management_enabled 1
  settings put global battery_saver_constants "vibration_disabled=true"
  
  log "✅ SYSTEM TWEAKS APPLIED"
}

# 7. Kernel Tweaks
kernel_tweaks() {
  log "🔧 APPLYING KERNEL TWEAKS"
  
  # Swappiness
  if [ -w /proc/sys/vm/swappiness ]; then
    echo 5 > /proc/sys/vm/swappiness
    log " ✔ Swappiness set to 5"
  fi
  
  # Cache pressure
  if [ -w /proc/sys/vm/vfs_cache_pressure ]; then
    echo 40 > /proc/sys/vm/vfs_cache_pressure
    log " ✔ Cache pressure set to 40"
  fi
  
  # Scheduler
  if [ -w /sys/block/mmcblk0/queue/scheduler ]; then
    echo noop > /sys/block/mmcblk0/queue/scheduler
    log " ✔ I/O Scheduler set to noop"
  fi
  
  # Dirty ratios
  if [ -w /proc/sys/vm/dirty_ratio ]; then
    echo 10 > /proc/sys/vm/dirty_ratio
    echo 5 > /proc/sys/vm/dirty_background_ratio
    log " ✔ Dirty ratios adjusted"
  fi
  
  log "✅ KERNEL TWEAKS COMPLETE"
}

# 8. Root Optimizations
root_optimizations() {
  if $ROOT_AVAILABLE; then
    log "🔥 STARTING ROOT OPTIMIZATIONS"
    
    # Deep cleaning
    su -c "rm -rf /cache/* /data/cache/* /data/dalvik-cache/* /data/anr/* /data/tombstones/*" 2>/dev/null && \
      ROOT_OPERATIONS="${ROOT_OPERATIONS}Deep cache cleaning\n"
    log " ✔ System cache cleaned"
    
    # App recompilation
    su -c "cmd package compile -m speed -f -a" 2>/dev/null && \
      ROOT_OPERATIONS="${ROOT_OPERATIONS}App recompilation\n"
    log " ✔ Apps recompiled"
    
    # ZRAM optimization
    if [ -b /dev/block/zram0 ]; then
      su -c "swapoff /dev/block/zram0 && mkswap /dev/block/zram0 && swapon /dev/block/zram0" 2>/dev/null && \
        ROOT_OPERATIONS="${ROOT_OPERATIONS}ZRAM optimization\n"
      log " ✔ ZRAM optimized"
    fi
    
    # CPU/GPU Boost
    [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] && \
      su -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    [ -w /sys/class/kgsl/kgsl-3d0/devfreq/governor ] && \
      su -c "echo performance > /sys/class/kgsl/kgsl-3d0/devfreq/governor"
    ROOT_OPERATIONS="${ROOT_OPERATIONS}CPU/GPU performance mode\n"
    log " ✔ CPU/GPU in performance mode"
    
    # Network optimization
    su -c "sysctl -w net.ipv4.tcp_window_scaling=1" 2>/dev/null
    su -c "sysctl -w net.ipv4.tcp_timestamps=1" 2>/dev/null
    su -c "sysctl -w net.ipv4.tcp_sack=1" 2>/dev/null
    ROOT_OPERATIONS="${ROOT_OPERATIONS}Network optimizations\n"
    log " ✔ TCP optimizations applied"
    
    log "✅ ROOT OPTIMIZATIONS COMPLETE"
  else
    log " ℹ️ Root not available - skipping advanced optimizations"
  fi
}

# 9. Generate Report
generate_report() {
  echo ""
  echo "#######################################################"
  echo "##                 FINAL REPORT                     ##"
  echo "##        $(date '+%Y-%m-%d %H:%M:%S')               ##"
  echo "#######################################################"
  echo ""
  
  echo "📊 OPTIMIZATION SUMMARY:"
  echo "- Storage freed: $STORAGE_FREED"
  echo "- Free RAM: $MEMORY_FREED"
  echo "- Apps optimized: $(echo -e "$OPTIMIZED_APPS" | wc -l)"
  echo "- Bloatware removed: $(echo -e "$BLOAT_REMOVED" | wc -l)"
  echo "- Background processes killed: $(echo -e "$BACKGROUND_KILLED" | wc -l)"
  echo "- Games optimized: $(echo -e "$GAMES_OPTIMIZED" | wc -l)"
  echo ""
  
  if [ -n "$ERRORS_FOUND" ]; then
    echo "⚠️ ERRORS ENCOUNTERED:"
    echo -e "$ERRORS_FOUND" | head -n 10
    [ $(echo -e "$ERRORS_FOUND" | wc -l) -gt 10 ] && echo "... (more errors in full log)"
    echo ""
  fi
  
  if $ROOT_AVAILABLE && [ -n "$ROOT_OPERATIONS" ]; then
    echo "🔓 ROOT OPERATIONS PERFORMED:"
    echo -e "$ROOT_OPERATIONS"
    echo ""
  fi
  
  echo "🕒 TOTAL TIME: $SECONDS seconds"
  echo "#######################################################"
}

# Execute all optimizations
{
  SECONDS=0
  clean_storage
  manage_memory
  optimize_cache
  debloat_system
  optimize_gaming
  system_tweaks
  kernel_tweaks
  root_optimizations
  generate_report
} | tee -a $LOG_FILE

echo "Full report saved to: $LOG_FILE"
echo ""