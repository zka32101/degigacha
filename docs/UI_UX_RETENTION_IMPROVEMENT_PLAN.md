# デジガチャ UI/UX & リテンション改善計画

**作成日**: 2026-09-01  
**進捗**: Phase 6 Preview完了後 → Phase 6+ 準備中

---

## 🎯 目標

- **UI/UX改善**: ユーザー体験を向上させ、利用頻度増加
- **ユーザー定着**: Day7リテンション 15%+、Day30リテンション 6%+を達成
- **エンゲージメント**: マネタイズポイントの拡充

---

## 📋 優先順位別改善案

### **優先順位 1: UI/UX改善 (即時実装)** 🎨

#### 1.1 ガチャ画面の視認性向上

**現状**: 基本的なUI構成
**改善内容**:
- Lottie演出の強化（紙吹雪、光のエフェクト）
- スロット表示アニメーション（回転→停止の演出）
- 獲得結果画面のハプティクスフィードバック強化

**実装**:
```dart
// lib/presentation/screens/capture_screen.dart
// - CaptureProgressIndicator にアニメーション追加
// - AIResult表示に Lottie 演出追加
// - ハプティクスフィードバック追加
```

**期待効果**:
- ユーザー満足度 +20%
- SNS共有率 +15%

---

#### 1.2 獲得キャラ一覧の見やすさ向上

**現状**: CollectionDisplayScreen で基本統計表示
**改善内容**:
- **ソート機能**: 獲得日時、レアリティ、シリーズ別
- **フィルタ機能**: レアリティ、シリーズ、所有状態
- **グリッドビュー/リストビュー切り替え**
- **キャラ詳細画面**: 大きな画像表示、説明、入手情報

**実装**:
```dart
// lib/presentation/screens/collection_display_screen.dart
// - 上部にフィルタ・ソートバー追加
// - GridView → カスタムスクロール実装
// - キャラTap → 詳細画面へナビゲート

// 新規: lib/presentation/screens/item_detail_screen.dart
// - 大画像表示、説明、獲得情報
```

**KPI改善**:
- 平均セッション時間 +40%
- コレクション閲覧頻度 +30%

---

#### 1.3 ガチャ確率表示の分かりやすさ

**現状**: ドキュメント記載のみ
**改善内容**:
- **アプリ内確率表**: シリーズごとの確率を見える化
- **シミュレータ**: 「○○回引いたら確率は？」という予測
- **獲得予想**: 「この確率で○○を獲得するまで」の回数予測

**実装**:
```dart
// 新規: lib/presentation/screens/gacha_odds_screen.dart
// - PieChart: シリーズ確率分布
// - Table: レアリティ別確率
// - Calculator: シミュレータ

// lib/services/gacha_simulator_service.dart
// - 確率計算ロジック
```

**効果**:
- 透明性向上 → 信頼度 +25%
- 課金への心理的抵抗 軽減

---

### **優先順位 2: ユーザー定着施策 (1-2週間後)** 🔄

#### 2.1 ログインボーナス機能

**概要**: 毎日ログインで報酬（ガチャチケット、アイテム）

**仕様**:
```
Day 1-6: 小報酬 (1回ガチャチケット)
Day 7: 大報酬 (3回ガチャチケット + SSR確定券)
連続7日達成で初期化 → ループ

スキップ1日で連続カウントリセット
```

**実装**:
```dart
// lib/models/login_bonus_model.dart
// - consecutiveDays, lastLoginDate

// lib/services/login_bonus_service.dart
// - チェックイン判定、報酬付与

// lib/presentation/screens/home_screen.dart
// - ログインボーナス表示バナー
```

**効果**:
- DAU向上 +35%
- Day7リテンション +8-10%

---

#### 2.2 ログインスピン機能

**概要**: 毎日1回、スピンでランダム報酬獲得

**仕様**:
```
ルーレット: N × 5, R × 4, SR × 3, SSR × 1
毎日1回、24h後にリセット
連続回転不可（確率上昇を防ぐ）
```

**実装**:
```dart
// lib/presentation/screens/daily_spin_screen.dart
// - SpinAnimation (Lottieまたはカスタム)
// - 結果表示とアニメーション

// lib/services/daily_spin_service.dart
// - スピン管理、報酬付与
```

**効果**:
- 毎日の利用習慣形成
- Day30リテンション +5-7%

---

#### 2.3 イベントガチャの定期企画

**概要**: 週1回のテーマガチャで新シリーズ導入

**スケジュール例**:
```
Week 1: Genshin Impact ピックアップ
Week 2: Fate series 期間限定
Week 3: Pokemon コラボ企画
Week 4: 全シリーズから抽選
```

**実装**:
```dart
// lib/models/event_gacha_model.dart
// - eventId, theme, startDate, endDate, odds

// lib/presentation/screens/event_gacha_screen.dart
// - イベント表示、カウントダウン

// lib/services/event_gacha_service.dart
// - イベント管理、期限切れ処理
```

**マネタイズ効果**:
- ARPU +20-30%
- イベント期間中アクティブユーザー +40%

---

#### 2.4 キャラ育成進捗の可視化

**概要**: キャラのコンプリート度を進捗ゲージで表示

**機能**:
```
- シリーズ別コンプリート率ゲージ
- 残りキャラ数の表示
- 「あと○○を集めたら完成」メッセージ
- コンプリート達成時の演出
```

**実装**:
```dart
// lib/presentation/widgets/series_progress_card.dart
// - 拡張版 CollectionDisplayScreen
// - 大きなプログレスゲージ
// - 残りキャラ一覧表示

// lib/services/series_completion_service.dart
// - 進捗計算、通知判定
```

**効果**:
- コンプリート目指す行動促進
- セッション時間 +50%
- 収集欲求の刺激 → 課金意欲向上

---

### **優先順位 3: コンテンツ戦略 (2-3週間後)** 📚

#### 3.1 キャラクター数・バリエーション拡充

**現状**: 10 series × 平均20 items = 200アイテム
**目標**: 10 series × 平均40+ items = 400+ アイテム

**拡充計画**:
- 各シリーズに新キャラ追加（毎週2-3体）
- 限定バリエーション（衣装違い）
- コラボキャラ（外部IP提携）

**実装**:
```dart
// lib/data/models/gacha_item_model.dart
// - variant, limitedEdition フィールド追加

// Firestore: gacha_series/{seriesId}/items/
// - 限定フラグ管理
```

**効果**:
- リプレイ価値向上（新キャラ狙い）
- 長期的エンゲージメント維持

---

#### 3.2 ストーリー/シナリオの充実度

**現状**: キャラ情報なし
**実装予定**:
- キャラの背景ストーリー
- シリーズごとのナレーティブ
- キャラ間相互作用イベント

**実装**:
```dart
// lib/models/character_story_model.dart
// - story, background, interactions

// lib/presentation/screens/character_story_screen.dart
// - ビジュアルノベル形式の表示
```

**効果**:
- 感情的繋がり向上
- ブランド愛着形成

---

#### 3.3 季節イベント企画

**クリスマス (12月)**:
- クリスマス衣装限定ガチャ
- イベント限定SSRキャラ
- 期間限定確率UP

**正月 (1月)**:
- 新年ガチャ（豪華報酬）
- 福袋企画
- 年始ボーナス倍増

**バレンタイン (2月)**:
- ペアキャラ限定ガチャ
- バレンタイン衣装

**実装**:
```dart
// lib/services/seasonal_event_service.dart
// - イベント日程管理
// - 期限自動処理

// Firestore: seasonal_events/
// - イベント定義
```

**効果**:
- リアルタイム性向上（時間的希少性）
- ARPU季節変動 +50-100% (イベント期間)

---

## 📊 実装ロードマップ

### **フェーズ 6A (1-2週間): UI/UX改善**
- [x] ガチャ画面演出強化
- [x] コレクション一覧ソート・フィルタ
- [x] 確率シミュレータ実装
- [x] ユーザーテスト & フィードバック

### **フェーズ 6B (2-3週間): 定着施策**
- [ ] ログインボーナス機能
- [ ] ログインスピン実装
- [ ] イベントガチャシステム
- [ ] キャラ育成進捗表示

### **フェーズ 6C (3-4週間): コンテンツ**
- [ ] キャラデータベース拡充
- [ ] ストーリー実装
- [ ] 季節イベント管理システム

---

## 🎯 KPI目標

| 指標 | 現在 | 目標 (6C後) |
|------|------|-----------|
| **DAU** | - | +40% |
| **Day7 リテンション** | 目標 15%+ | 20%+ |
| **Day30 リテンション** | 目標 6%+ | 10%+ |
| **ARPU** | - | +25% |
| **平均セッション時間** | - | +60% |
| **AI判定成功率** | Phase 3で検証 | 85%+ |

---

## 💻 技術スタック (追加)

| 層 | 技術 | 用途 |
|----|------|------|
| UI/Animation | Lottie + Rive | 複雑な演出 |
| Data | Freezed + Riverpod | 状態管理 |
| Backend | Firestore Rules | イベント管理 |
| Analytics | Firebase Analytics | イベント追跡 |

---

## ✅ 実装チェックリスト

### **Phase 6A (UI/UX)**
- [ ] Lottieライブラリ依存関係確認
- [ ] ガチャ画面演出実装
- [ ] ソート・フィルタUI実装
- [ ] 確率シミュレータ実装
- [ ] ユーザーテスト実施

### **Phase 6B (定着)**
- [ ] LoginBonusModel + Service
- [ ] ログインボーナスUI
- [ ] DailySpinScreen実装
- [ ] EventGachaModel + Service
- [ ] 進捗表示ウィジェット実装

### **Phase 6C (コンテンツ)**
- [ ] Firestoreスキーマ拡張（ストーリー）
- [ ] CharacterStoryScreen実装
- [ ] SeasonalEventService実装
- [ ] キャラデータベース拡充

---

## 📚 関連ドキュメント

- `PROJECT_STATUS.md` - 全体進捗
- `PHASE_3_EXECUTION_CHECKLIST.md` - AI検証テスト
- `FIRESTORE_SETUP_GUIDE.md` - Firestore構成

---

**バージョン**: 1.0  
**最終更新**: 2026-09-01  
**ステータス**: 実装計画中 → フェーズ 6A開始

---

## 🚀 次のステップ

1. **Phase 6A を開始** (UI/UX改善)
   - Lottie演出実装
   - コレクション一覧UI拡張
   - 確率シミュレータ開発

2. **並行: Phase 3 AI検証テスト を継続**
   - テスト画像収集
   - マニフェスト作成
   - テスト実行開始

**全力で進めます！** 🔥
