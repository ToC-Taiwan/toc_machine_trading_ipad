#!/bin/bash

flutter build ipa --release --export-method development

python3 ./scripts/add_build.py

ideviceinstaller --uninstall com.tocandraw.tocMachineTradingIpad
ideviceinstaller -i ./build/ios/ipa/toc_machine_trading_ipad.ipa
