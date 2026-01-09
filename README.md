# Sukasi

macOS用の透かし画像オーバーレイアプリ。ショートカット暗記などに。

## 機能

- 半透明画像を最前面に表示
- クリック透過（背後のアプリを操作可能）
- グローバルホットキーでトグル（デフォルト: ⌥⌘H）
- メニューバー常駐 / Dock非表示

## ビルド

```bash
./scripts/build.sh
./scripts/run.sh
```

## 設定リセット

```bash
# 全設定をリセット
defaults delete me.takanakahiko.Sukasi

# 画像選択のみリセット（デフォルト画像に戻す）
defaults delete me.takanakahiko.Sukasi imagePath
```

## 要件

- macOS 13.0+
- Xcode
