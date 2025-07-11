# **Android Ultimate Optimizer - Usage Guide**

## **Compatibility Requirements**
- Android 5.0+ devices
- 10MB free storage space
- Internet connection for script download

## **1. Root Version (Termux)**

### **Installation Steps**
1. Open Termux app
2. Run these commands sequentially:
```bash
curl -o optimizer_root.sh https://github.com/ElxSnowkk/Shell-optimization-for-Android.git
chmod +x optimizer_root.sh
su -c ./optimizer_root.sh
```

### **Output & Results**
- Real-time optimization report in terminal
- Detailed logs saved to `/sdcard/AndroidOptimizer.log`

## **2. ADB Version (Brevent)**

### **Installation Method**
1. Manual download:
   - Visit: https://github.com/youru
   - Download `optimizer_adb.sh`
   - Save to device's `/sdcard/` directory

2. Execution via Brevent:
   - Launch Brevent app
   - Select "Run Command"
   - Enter:
   ```bash
   sh /sdcard/optimizer_adb.sh
   ```

### **Output & Results**
- Optimization progress visible in Brevent
- Complete logs stored in `/sdcard/OtimizadorADB.log`

## **Key Notes**
- Root version provides full system optimization
- ADB version has limited functionality
- Always check protected apps list
- Recommended to backup before optimization
- Check log files for troubleshooting

**License:** MIT License
