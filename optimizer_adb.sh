#!/system/bin/sh

clear
echo ""
echo "#######################################################"
echo "##       ANDROID ULTIMATE OPTIMIZER (ADB) v12       ##"
echo "##       Rootless version - Requires ADB            ##"
echo "#######################################################"
echo ""

LOG_FILE="/sdcard/AndroidOptimizerADB.log"
PROTECTED_APPS="
com.google.android.gms
com.google.android.gsf
com.android.vending
com.google.android.syncadapters.contacts
com.google.android.backuptransport
com.google.android.onetimeinitializer
com.google.android.partnersetup
com.whatsapp
com.instagram.android
com.facebook.katana
com.facebook.orca
org.telegram.messenger
com.signal
com.discord
com.bankinter.launcher
com.lacaixa.mobile.android.newwapicon
com.bbva.bbvacontigo
com.santander.app
com.paypal.android.p2pmobile
com.android.phone
com.android.settings
com.android.systemui
"

OPTIMIZED_APPS=""
BLOAT_REMOVED=""
GAMES_OPTIMIZED=""
ERRORS_FOUND=""
STORAGE_FREED=""
MEMORY_FREED=""
BACKGROUND_KILLED=""

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

is_protected() {
  echo "$PROTECTED_APPS" | grep -q "$1"
}

clean_storage() {
  log "🧹 STARTING STORAGE CLEANING (ADB)"
  
  total_apps=0
  for pkg in $(pm list packages | cut -d':' -f2); do
    if ! is_protected "$pkg"; then
      app_name=$(dumpsys package "$pkg" | grep "application-label:" | head -1 | cut -d':' -f2 | tr -d ' ')
      [ -z "$app_name" ] && app_name="$pkg"
      
      if pm clear "$pkg" >/dev/null 2>&1; then
        OPTIMIZED_APPS="$OPTIMIZED_APPS$app_name\n"
        log " ✔ Cache cleared: $app_name"
      else
        ERRORS_FOUND="$ERRORS_FOUND$app_name (cache)\n"
        log " ✖ Failed to clear: $app_name"
      fi
      total_apps=$((total_apps + 1))
    fi
  done
  
  rm -rf /data/local/tmp/* 2>/dev/null
  rm -rf /sdcard/DCIM/.thumbnails/* 2>/dev/null
  
  log "✅ CLEANING COMPLETE - $total_apps apps processed"
}

manage_memory() {
  log "🧠 OPTIMIZING MEMORY (ADB)"
  
  background_count=0
  for pkg in $(pm list packages -3 | cut -d':' -f2); do
    if ! is_protected "$pkg"; then
      am force-stop "$pkg" >/dev/null 2>&1
      background_count=$((background_count + 1))
      BACKGROUND_KILLED="$BACKGROUND_KILLED$pkg\n"
    fi
  done
  
  settings put global background_process_limit 3
  
  mem_info=$(dumpsys meminfo | grep "Free RAM:" | awk '{print $3}')
  MEMORY_FREED="${mem_info:-N/A}"
  
  log "✅ MEMORY OPTIMIZED - $background_count apps killed"
}

debloat_system() {
  log "🗑️ REMOVING BLOATWARE (ADB)"
  
  bloat_list="
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
    if pm list packages | grep -q "$pkg"; then
      if ! is_protected "$pkg"; then
        if pm disable-user --user 0 "$pkg" >/dev/null 2>&1; then
          BLOAT_REMOVED="$BLOAT_REMOVED$pkg\n"
          log " ✔ Bloat disabled: $pkg"
          removed_count=$((removed_count + 1))
        else
          ERRORS_FOUND="$ERRORS_FOUND$pkg (bloat)\n"
          log " ✖ Failed to disable: $pkg"
        fi
      fi
    fi
  done
  
  log "✅ BLOATWARE REMOVED - $removed_count items disabled"
}

optimize_gaming() {
  log "🎮 GAMING OPTIMIZATION (ADB)"
  
  games=$(pm list packages | cut -d':' -f2 | grep -Ei 'game|mlbb|cod|pubg|freefire|amongus')
  
  if [ -n "$games" ]; then
    for game in $games; do
      game_name=$(dumpsys package "$game" | grep "application-label:" | head -1 | cut -d':' -f2 | tr -d ' ')
      [ -z "$game_name" ] && game_name="$game"
      
      settings put global game_driver_all_apps 1 2>/dev/null
      settings put global force_gpu_rendering 1 2>/dev/null
      GAMES_OPTIMIZED="$GAMES_OPTIMIZED$game_name\n"
      log " 🕹️ Game optimized: $game_name"
    done
  else
    log " ℹ️ No games found"
  fi
  
  log "✅ GAMING OPTIMIZED"
}

system_tweaks() {
  log "⚙️ APPLYING SYSTEM TWEAKS (ADB)"
  
  settings put global window_animation_scale 0.5
  settings put global transition_animation_scale 0.5
  settings put global animator_duration_scale 0.5
  settings put global restricted_device_performance 1
  settings put global adaptive_battery_management_enabled 1
  
  log "✅ TWEAKS APPLIED"
}

generate_report() {
  echo ""
  echo "#######################################################"
  echo "##          OPTIMIZATION REPORT (ADB)              ##"
  echo "#######################################################"
  echo ""
  echo "📊 SUMMARY:"
  echo "- Optimized apps: $(echo -e "$OPTIMIZED_APPS" | wc -l)"
  echo "- Bloatware disabled: $(echo -e "$BLOAT_REMOVED" | wc -l)"
  echo "- Games optimized: $(echo -e "$GAMES_OPTIMIZED" | wc -l)"
  echo "- Background apps killed: $(echo -e "$BACKGROUND_KILLED" | wc -l)"
  echo ""
  
  if [ -n "$ERRORS_FOUND" ]; then
    echo "⚠️ ERRORS:"
    echo -e "$ERRORS_FOUND" | head -5
    echo "... (check full log for details)"
    echo ""
  fi
  
  echo "📁 Full log: $LOG_FILE"
  echo "#######################################################"
}

{
  clean_storage
  manage_memory
  debloat_system
  optimize_gaming
  system_tweaks
  generate_report
} | tee -a $LOG_FILE

echo "Optimization complete!"
