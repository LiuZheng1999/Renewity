#!/usr/bin/env python3
"""Patch remaining legal markdown files and build GitHub Pages HTML in docs/."""

from __future__ import annotations

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGAL = ROOT / "Renewity" / "Legal"
DOCS = ROOT / "docs"

LANGS = [
    ("zh-Hans", "简体中文", "隐私政策", "使用条款"),
    ("zh-Hant", "繁體中文", "隱私權政策", "使用者條款"),
    ("en", "English", "Privacy Policy", "Terms of Use"),
    ("ja", "日本語", "プライバシーポリシー", "利用規約"),
    ("ko", "한국어", "개인정보 처리방침", "이용약관"),
    ("de", "Deutsch", "Datenschutz", "Nutzungsbedingungen"),
    ("fr", "Français", "Confidentialité", "Conditions d’utilisation"),
    ("es", "Español", "Privacidad", "Términos de uso"),
    ("it", "Italiano", "Privacy", "Termini di utilizzo"),
    ("pt-BR", "Português (Brasil)", "Privacidade", "Termos de uso"),
]

WEBSITE = "https://liuzheng1999.github.io/Renewity"
SUPPORT_EMAIL = "philiptrip1975@gmail.com"

SUPPORT_TITLES = {
    "zh-Hans": "技术支持",
    "zh-Hant": "技術支援",
    "en": "Support",
    "ja": "サポート",
    "ko": "고객 지원",
    "de": "Support",
    "fr": "Assistance",
    "es": "Soporte",
    "it": "Assistenza",
    "pt-BR": "Suporte",
}

SUPPORT_MD = {
    "zh-Hans": f"""# 技术支持

**Renewity** 是一款订阅记账应用。本页供 App Store 用户联系支持，并说明常见问题。

## 联系我们

请发送邮件至 **{SUPPORT_EMAIL}**。

也可以在 App 的「设置 → 支持」里直接写信。来信请尽量写明：

- 设备型号和 iOS 版本
- App 版本
- 问题出现的步骤

网页：{WEBSITE}/support/

## 常见问题

### iCloud 同步打不开或很慢

登录同一 Apple 账户并在系统设置中打开 iCloud 后，订阅、分类、支付方式、外观、提醒时间和头像会通过 Apple 的 CloudKit 在设备之间同步。这不是 iCloud Drive 备份，也不是 Pro 功能。首次同步可能需要几分钟。

### 如何备份数据

在「设置 → 数据与同步」可把数据导出为 JSON，保存到文件 App 或其他位置。文件导出免费。

### 提醒没有出现

提醒是设备上的本地通知。请在系统设置中允许 Renewity 发送通知。App 会预先安排未来若干期，并在你打开 App 时重新排队。若长时间不打开 App，之后的提醒可能不再出现，直到再次打开。

### 购买、取消或退款

Pro 的月度、年度和终身购买通过 Apple 完成。管理订阅、取消自动续订或申请退款，请使用 Apple 账户：设置 → Apple 账户 → 订阅，或联系 Apple 支持。我们无法直接处理 App Store 付款。

### 一次性订阅

一次性购买只记录到期日，不能开启试用。金额不计入概览和日历的合计；日历上到期那天仍会显示该服务。

## 隐私政策与使用条款

- 隐私政策：{WEBSITE}/privacy/
- 使用条款：{WEBSITE}/terms/
""",
    "zh-Hant": f"""# 技術支援

**Renewity** 是一款訂閱記帳 App。本頁供 App Store 使用者聯絡支援，並說明常見問題。

## 聯絡我們

請寄信至 **{SUPPORT_EMAIL}**。

也可以在 App 的「設定 → 支援」直接寫信。來信請盡量註明：

- 裝置型號和 iOS 版本
- App 版本
- 問題出現的步驟

網頁：{WEBSITE}/support/

## 常見問題

### iCloud 同步打不開或很慢

登入同一 Apple 帳號並在系統設定中打開 iCloud 後，訂閱、分類、支付方式、外觀、提醒時間和頭像會透過 Apple 的 CloudKit 在裝置之間同步。這不是 iCloud Drive 備份，也不是 Pro 功能。首次同步可能需要幾分鐘。

### 如何備份資料

在「設定 → 資料與同步」可把資料匯出為 JSON，儲存到檔案 App 或其他位置。檔案匯出免費。

### 提醒沒有出現

提醒是裝置上的本機通知。請在系統設定中允許 Renewity 傳送通知。App 會預先安排未來若干期，並在你打開 App 時重新排隊。若長時間不打開 App，之後的提醒可能不再出現，直到再次打開。

### 購買、取消或退款

Pro 的月度、年度和終身購買透過 Apple 完成。管理訂閱、取消自動續訂或申請退款，請使用 Apple 帳號：設定 → Apple 帳號 → 訂閱，或聯絡 Apple 支援。我們無法直接處理 App Store 付款。

### 一次性訂閱

一次性購買只記錄到期日，不能開啟試用。金額不計入概覽和日曆的合計；日曆上到期那天仍會顯示該服務。

## 隱私權政策與使用者條款

- 隱私權政策：{WEBSITE}/privacy/
- 使用者條款：{WEBSITE}/terms/
""",
    "en": f"""# Support

**Renewity** is a subscription tracker. Use this page to contact support and find answers to common questions.

## Contact

Email **{SUPPORT_EMAIL}**.

You can also write from the app: Settings → Support. Please include:

- Device model and iOS version
- App version
- Steps to reproduce the issue

Web: {WEBSITE}/support/

## FAQ

### iCloud sync is missing or slow

After you sign in with the same Apple Account and turn on iCloud, subscriptions, categories, payment methods, appearance, reminder time, and your avatar sync across devices through Apple CloudKit. This is not an iCloud Drive backup, and it is not a Pro feature. The first sync can take a few minutes.

### How do I back up my data?

In Settings → Data & Sync you can export JSON to the Files app or another location. File export is free.

### Reminders did not appear

Reminders are local notifications on your device. Allow notifications for Renewity in Settings. The app schedules several upcoming reminders and refreshes the queue when you open it. If you leave the app closed for a long time, later reminders may stop until you open it again.

### Purchases, cancellation, and refunds

Monthly, annual, and lifetime Pro purchases go through Apple. To manage a subscription, cancel auto-renewal, or request a refund, use your Apple Account: Settings → Apple Account → Subscriptions, or contact Apple Support. We cannot process App Store payments directly.

### One-time purchases

A one-time item only stores an expiry date and cannot have a trial. Its amount is not included in Overview or Calendar totals; the service still appears on the expiry day in the calendar.

## Privacy Policy and Terms of Use

- Privacy Policy: {WEBSITE}/privacy/
- Terms of Use: {WEBSITE}/terms/
""",
    "ja": f"""# サポート

**Renewity** はサブスクリプション記録アプリです。お問い合わせとよくある質問は本ページをご利用ください。

## お問い合わせ

**{SUPPORT_EMAIL}** までメールしてください。

アプリ内の「設定 → サポート」から送ることもできます。可能なら次を書いてください。

- 機種と iOS バージョン
- アプリのバージョン
- 問題の再現手順

ウェブ：{WEBSITE}/support/

## よくある質問

### iCloud 同期が動かない／遅い

同じ Apple Account でサインインし、設定で iCloud をオンにすると、サブスク・カテゴリ・支払い方法・外観・通知時刻・アバターが Apple の CloudKit で端末間同期されます。iCloud Drive のバックアップではなく、Pro 機能でもありません。初回は数分かかることがあります。

### データのバックアップ

「設定 → データと同期」から JSON をファイル App などに書き出せます。書き出しは無料です。

### リマインダーが来ない

リマインダーは端末のローカル通知です。設定で Renewity の通知を許可してください。アプリは今後数回分を予約し、起動時に並べ直します。長期間起動しないと、以降の通知が止まることがあります。

### 購入・解約・返金

Pro の月額・年額・買い切りは Apple 経由です。管理・自動更新の停止・返金は、設定 → Apple Account → サブスクリプション、または Apple サポートで行ってください。App Store の決済はこちらでは処理できません。

### 都度払い

都度払いは有効期限のみ記録し、無料期間は使えません。金額は概要とカレンダーの合計に入りません。カレンダーの期限当日には表示されます。

## プライバシーポリシーと利用規約

- プライバシーポリシー：{WEBSITE}/privacy/
- 利用規約：{WEBSITE}/terms/
""",
    "ko": f"""# 고객 지원

**Renewity**는 구독 기록 앱입니다. 문의와 자주 묻는 질문은 이 페이지를 사용하세요.

## 문의

**{SUPPORT_EMAIL}** 으로 메일을 보내 주세요.

앱의 「설정 → 지원」에서도 보낼 수 있습니다. 가능하면 다음을 적어 주세요.

- 기기 모델과 iOS 버전
- 앱 버전
- 문제가 나타난 단계

웹: {WEBSITE}/support/

## 자주 묻는 질문

### iCloud 동기화가 안 되거나 느림

같은 Apple 계정으로 로그인하고 설정에서 iCloud를 켜면 구독, 분류, 결제 수단, 외관, 알림 시각, 아바타가 Apple CloudKit으로 기기 간에 동기화됩니다. iCloud Drive 백업이 아니며 Pro 기능도 아닙니다. 첫 동기화는 몇 분 걸릴 수 있습니다.

### 데이터 백업

「설정 → 데이터 및 동기화」에서 JSON을 파일 앱 등으로 내보낼 수 있습니다. 파일 내보내기는 무료입니다.

### 알림이 안 옴

알림은 기기의 로컬 알림입니다. 설정에서 Renewity 알림을 허용하세요. 앱이 앞으로 여러 회차를 예약하고, 열 때 다시 정렬합니다. 오래 열지 않으면 이후 알림이 멈출 수 있습니다.

### 구매, 해지, 환불

Pro 월간·연간·평생 구매는 Apple을 통해 이루어집니다. 구독 관리, 자동 갱신 해지, 환불은 설정 → Apple 계정 → 구독, 또는 Apple 지원을 이용하세요. App Store 결제는 여기서 처리할 수 없습니다.

### 일회성 구독

일회성 항목은 만료일만 기록하며 체험을 켤 수 없습니다. 금액은 개요와 캘린더 합계에 포함되지 않고, 만료일에는 캘린더에 표시됩니다.

## 개인정보 처리방침과 이용약관

- 개인정보 처리방침: {WEBSITE}/privacy/
- 이용약관: {WEBSITE}/terms/
""",
    "de": f"""# Support

**Renewity** ist eine Abo-Übersicht. Auf dieser Seite erreichst du den Support und findest Antworten auf häufige Fragen.

## Kontakt

Schreib an **{SUPPORT_EMAIL}**.

Du kannst auch in der App unter Einstellungen → Support schreiben. Bitte nenne nach Möglichkeit:

- Gerätemodell und iOS-Version
- App-Version
- Schritte, mit denen das Problem auftritt

Web: {WEBSITE}/support/

## FAQ

### iCloud-Sync fehlt oder ist langsam

Mit demselben Apple Account und aktiviertem iCloud synchronisiert CloudKit Abos, Kategorien, Zahlungsmethoden, Darstellung, Erinnerungszeit und Avatar zwischen Geräten. Das ist kein iCloud-Drive-Backup und keine Pro-Funktion. Die erste Sync kann einige Minuten dauern.

### Daten sichern

Unter Einstellungen → Daten und Sync kannst du JSON in die Dateien-App oder woanders exportieren. Der Export ist kostenlos.

### Erinnerungen kommen nicht

Erinnerungen sind lokale Mitteilungen. Erlaube Mitteilungen für Renewity in den Einstellungen. Die App plant mehrere künftige Termine und aktualisiert die Warteschlange beim Öffnen. Bleibt die App lange geschlossen, können spätere Erinnerungen ausbleiben.

### Käufe, Kündigung, Erstattung

Monats-, Jahres- und Lifetime-Pro laufen über Apple. Abo verwalten, Auto-Verlängerung beenden oder erstatten: Einstellungen → Apple Account → Abos oder Apple Support. App-Store-Zahlungen können wir nicht selbst abwickeln.

### Einmalige Käufe

Ein Einmalkauf speichert nur das Ablaufdatum und hat keine Testphase. Der Betrag zählt nicht zu Übersicht und Kalender-Summe; am Ablaufdatum erscheint der Dienst trotzdem im Kalender.

## Datenschutz und Nutzungsbedingungen

- Datenschutz: {WEBSITE}/privacy/
- Nutzungsbedingungen: {WEBSITE}/terms/
""",
    "fr": f"""# Assistance

**Renewity** est une app de suivi d’abonnements. Cette page sert à contacter l’assistance et à répondre aux questions fréquentes.

## Contact

Écrivez à **{SUPPORT_EMAIL}**.

Vous pouvez aussi écrire depuis l’App : Réglages → Assistance. Indiquez si possible :

- modèle et version d’iOS
- version de l’App
- étapes pour reproduire le problème

Web : {WEBSITE}/support/

## FAQ

### La sync iCloud ne marche pas ou est lente

Connecté au même compte Apple avec iCloud activé, CloudKit synchronise abonnements, catégories, moyens de paiement, apparence, heure de rappel et avatar. Ce n’est pas une sauvegarde iCloud Drive, ni une fonction Pro. La première sync peut prendre quelques minutes.

### Sauvegarder les données

Dans Réglages → Données et sync, exportez un JSON vers Fichiers ou un autre emplacement. L’export est gratuit.

### Les rappels n’apparaissent pas

Les rappels sont des notifications locales. Autorisez les notifications Renewity dans Réglages. L’App planifie plusieurs échéances et rafraîchit la file à l’ouverture. Si vous ne l’ouvrez pas longtemps, les rappels suivants peuvent s’arrêter.

### Achats, résiliation, remboursement

Les achats Pro mensuels, annuels et à vie passent par Apple. Pour gérer, arrêter le renouvellement automatique ou demander un remboursement : Réglages → Compte Apple → Abonnements, ou Assistance Apple. Nous ne traitons pas les paiements App Store.

### Achat unique

Un achat unique n’enregistre que la date d’expiration et n’a pas d’essai. Le montant n’entre pas dans l’aperçu ni le total du calendrier ; le service apparaît quand même le jour d’expiration.

## Confidentialité et conditions

- Confidentialité : {WEBSITE}/privacy/
- Conditions d’utilisation : {WEBSITE}/terms/
""",
    "es": f"""# Soporte

**Renewity** es una app para llevar suscripciones. Usa esta página para contactar con soporte y ver preguntas frecuentes.

## Contacto

Escribe a **{SUPPORT_EMAIL}**.

También puedes escribir desde la app: Ajustes → Soporte. Incluye si puedes:

- modelo y versión de iOS
- versión de la app
- pasos para reproducir el problema

Web: {WEBSITE}/support/

## Preguntas frecuentes

### iCloud no sincroniza o va lento

Con la misma cuenta de Apple e iCloud activado, CloudKit sincroniza suscripciones, categorías, métodos de pago, apariencia, hora de aviso y avatar. No es una copia en iCloud Drive ni una función Pro. La primera sincronización puede tardar unos minutos.

### Cómo hacer copia

En Ajustes → Datos y sincronización puedes exportar JSON a Archivos u otra ubicación. Exportar es gratis.

### No llegan los recordatorios

Son notificaciones locales. Permite notificaciones de Renewity en Ajustes. La app programa varias fechas y actualiza la cola al abrirla. Si no la abres durante mucho tiempo, los avisos posteriores pueden parar.

### Compras, cancelación y reembolsos

Las compras Pro mensuales, anuales y de por vida van por Apple. Para gestionar, cancelar la renovación automática o pedir reembolso: Ajustes → Cuenta de Apple → Suscripciones, o Soporte de Apple. No procesamos pagos de App Store.

### Compra única

Un pago único solo guarda la fecha de caducidad y no admite prueba. El importe no entra en el resumen ni en el total del calendario; el servicio sí aparece el día de caducidad.

## Privacidad y términos

- Privacidad: {WEBSITE}/privacy/
- Términos de uso: {WEBSITE}/terms/
""",
    "it": f"""# Assistenza

**Renewity** è un’app per tenere gli abbonamenti. Usa questa pagina per contattare l’assistenza e leggere le domande frequenti.

## Contatti

Scrivi a **{SUPPORT_EMAIL}**.

Puoi anche scrivere dall’app: Impostazioni → Assistenza. Se puoi, indica:

- modello e versione iOS
- versione dell’app
- passaggi per riprodurre il problema

Web: {WEBSITE}/support/

## Domande frequenti

### La sync iCloud non parte o è lenta

Con lo stesso Account Apple e iCloud attivo, CloudKit sincronizza abbonamenti, categorie, metodi di pagamento, aspetto, orario dei promemoria e avatar. Non è un backup su iCloud Drive né una funzione Pro. La prima sync può richiedere alcuni minuti.

### Come fare il backup

In Impostazioni → Dati e sync puoi esportare un JSON in File o altrove. L’esportazione è gratuita.

### I promemoria non arrivano

Sono notifiche locali. Consenti le notifiche di Renewity in Impostazioni. L’app pianifica più scadenze e aggiorna la coda all’apertura. Se non apri l’app a lungo, i promemoria successivi possono interrompersi.

### Acquisti, disdetta e rimborsi

Gli acquisti Pro mensili, annuali e a vita passano da Apple. Per gestire, interrompere il rinnovo automatico o chiedere un rimborso: Impostazioni → Account Apple → Abbonamenti, oppure Assistenza Apple. Non elaboriamo i pagamenti App Store.

### Acquisto una tantum

Un acquisto una tantum registra solo la data di scadenza e non ha prova. L’importo non entra in panoramica né nel totale del calendario; il servizio compare comunque il giorno di scadenza.

## Privacy e termini

- Privacy: {WEBSITE}/privacy/
- Termini di utilizzo: {WEBSITE}/terms/
""",
    "pt-BR": f"""# Suporte

**Renewity** é um app para acompanhar assinaturas. Use esta página para falar com o suporte e ver perguntas frequentes.

## Contato

Escreva para **{SUPPORT_EMAIL}**.

Você também pode escrever no app: Ajustes → Suporte. Se possível, inclua:

- modelo e versão do iOS
- versão do app
- passos para reproduzir o problema

Web: {WEBSITE}/support/

## Perguntas frequentes

### A sincronização do iCloud não funciona ou está lenta

Com a mesma Conta Apple e o iCloud ligado, o CloudKit sincroniza assinaturas, categorias, formas de pagamento, aparência, horário do lembrete e avatar. Não é backup do iCloud Drive nem recurso Pro. A primeira sincronização pode levar alguns minutos.

### Como fazer backup

Em Ajustes → Dados e sincronização você exporta JSON para o app Arquivos ou outro local. A exportação é gratuita.

### Os lembretes não aparecem

São notificações locais. Permita notificações do Renewity em Ajustes. O app agenda várias datas e atualiza a fila ao abrir. Se você não abrir o app por muito tempo, os próximos avisos podem parar.

### Compras, cancelamento e reembolso

As compras Pro mensais, anuais e vitalícias passam pela Apple. Para gerenciar, cancelar a renovação automática ou pedir reembolso: Ajustes → Conta Apple → Assinaturas, ou Suporte Apple. Não processamos pagamentos da App Store.

### Compra única

Uma compra única guarda só a data de validade e não tem teste. O valor não entra na visão geral nem no total do calendário; o serviço ainda aparece no dia do vencimento.

## Privacidade e termos

- Privacidade: {WEBSITE}/privacy/
- Termos de uso: {WEBSITE}/terms/
""",
}

DATE_REPLACEMENTS = [
    ("2026 年 8 月 14 日", "2026 年 8 月 20 日"),
    ("August 14, 2026", "August 20, 2026"),
    ("14. August 2026", "20. August 2026"),
    ("14 août 2026", "20 août 2026"),
    ("14 de agosto de 2026", "20 de agosto de 2026"),
    ("14 agosto 2026", "20 agosto 2026"),
    ("2026年8月14日", "2026年8月20日"),
    ("2026년 8월 14일", "2026년 8월 20일"),
]

WEBSITE_BLOCKS = {
    "privacy": {
        "zh-Hant": f"網頁版與應用內文本一致，發布於 GitHub Pages：  \n**{WEBSITE}/privacy/**\n\n",
        "ja": f"アプリ内と同じ文面のウェブ版：  \n**{WEBSITE}/privacy/**\n\n",
        "ko": f"앱과 동일한 웹 버전은 GitHub Pages에 게시됩니다:  \n**{WEBSITE}/privacy/**\n\n",
        "de": f"Eine Webfassung mit demselben Text liegt auf GitHub Pages:  \n**{WEBSITE}/privacy/**\n\n",
        "fr": f"Une version web identique au texte de l’App est publiée sur GitHub Pages :  \n**{WEBSITE}/privacy/**\n\n",
        "es": f"Hay una copia web igual al texto de la app en GitHub Pages:  \n**{WEBSITE}/privacy/**\n\n",
        "it": f"Una copia web identica al testo in-app è su GitHub Pages:  \n**{WEBSITE}/privacy/**\n\n",
        "pt-BR": f"Uma cópia web igual ao texto do app está no GitHub Pages:  \n**{WEBSITE}/privacy/**\n\n",
    },
    "terms": {
        "zh-Hant": f"網頁版與應用內文本一致，發布於 GitHub Pages：  \n**{WEBSITE}/terms/**\n\n",
        "ja": f"アプリ内と同じ文面のウェブ版：  \n**{WEBSITE}/terms/**\n\n",
        "ko": f"앱과 동일한 웹 버전은 GitHub Pages에 게시됩니다:  \n**{WEBSITE}/terms/**\n\n",
        "de": f"Eine Webfassung mit demselben Text liegt auf GitHub Pages:  \n**{WEBSITE}/terms/**\n\n",
        "fr": f"Une version web identique au texte de l’App est publiée sur GitHub Pages :  \n**{WEBSITE}/terms/**\n\n",
        "es": f"Hay una copia web igual al texto de la app en GitHub Pages:  \n**{WEBSITE}/terms/**\n\n",
        "it": f"Una copia web identica al testo in-app è su GitHub Pages:  \n**{WEBSITE}/terms/**\n\n",
        "pt-BR": f"Uma cópia web igual ao texto do app está no GitHub Pages:  \n**{WEBSITE}/terms/**\n\n",
    },
}

EXTRA_SECTIONS = {
    "privacy": {
        "zh-Hant": """
## 補充說明（2026 年 8 月 20 日）

- 本應用程式需要 iOS 18 或更高版本。
- 登入 iCloud 後，記帳資料、外觀、提醒時間和頭像可透過 iCloud 在你的裝置間同步。你也可以自行匯出 JSON 檔。
- 續費與試用提醒為本機通知。應用會預先安排未來若干期，並在你打開應用時重新排隊。系統對待發送通知數量有上限，長時間不打開應用可能導致後續提醒不再出現。
- 本應用包含隱私清單並聲明不進行跨 App 追蹤。
""",
        "ja": """
## 追記（2026年8月20日）

- 本アプリは iOS 18 以降が必要です。
- iCloud にサインインしている場合、記録・外観・通知時刻・アバターは iCloud で端末間同期できます。JSON の書き出しもできます。
- 更新・無料期間のリマインダーはローカル通知です。今後数回分を予約し、アプリ起動時に再スケジュールします。OS の保留上限があるため、長期間起動しないと以降の通知が止まることがあります。
- プライバシマニフェストを含め、クロスアプリ追跡は行いません。
""",
        "ko": """
## 추가 안내 (2026년 8월 20일)

- 이 앱은 iOS 18 이상이 필요합니다.
- iCloud에 로그인하면 기록·외관·알림 시각·아바타가 iCloud로 기기 간 동기화됩니다. JSON 내보내기도 할 수 있습니다.
- 갱신·체험 알림은 로컬 알림입니다. 앞으로 여러 회차를 미리 예약하고, 앱을 열 때 다시 정렬합니다. 시스템 대기 알림 수 제한 때문에 오래 앱을 열지 않으면 이후 알림이 멈출 수 있습니다.
- 개인정보 매니페스트를 포함하며 다른 앱을 가로질러 추적하지 않습니다.
""",
        "de": """
## Ergänzung (20. August 2026)

- Die App benötigt iOS 18 oder neuer.
- Mit iCloud-Anmeldung können Abos, Darstellung, Erinnerungszeit und Avatar per iCloud zwischen Geräten synchronisiert werden. Ein JSON-Export ist ebenfalls möglich.
- Erinnerungen sind lokale Mitteilungen. Die App plant mehrere künftige Termine und aktualisiert die Warteschlange beim Öffnen. Wegen der Systemgrenze können spätere Erinnerungen ausbleiben, wenn die App lange nicht geöffnet wird.
- Die App enthält ein Privacy Manifest und trackt nicht über andere Apps hinweg.
""",
        "fr": """
## Complément (20 août 2026)

- L’App nécessite iOS 18 ou une version ultérieure.
- Connecté à iCloud, l’App synchronise abonnements, apparence, heure de rappel et avatar via iCloud. Vous pouvez aussi exporter un JSON.
- Les rappels sont des notifications locales. L’App planifie plusieurs échéances à l’avance et rafraîchit la file à l’ouverture. Faute d’ouvrir l’App longtemps, les rappels suivants peuvent s’arrêter (limite système).
- L’App inclut un manifeste de confidentialité et ne fait pas de suivi inter-apps.
""",
        "es": """
## Nota adicional (20 de agosto de 2026)

- La app requiere iOS 18 o posterior.
- Con iCloud, la app sincroniza suscripciones, apariencia, hora de aviso y avatar. También puedes exportar un JSON.
- Los recordatorios son notificaciones locales. La app programa varias fechas futuras y actualiza la cola al abrirla. Si no la abres durante mucho tiempo, los avisos posteriores pueden detenerse por el límite del sistema.
- Incluye Privacy Manifest y no hace seguimiento entre apps.
""",
        "it": """
## Integrazione (20 agosto 2026)

- L’app richiede iOS 18 o successivo.
- Con iCloud, l’app sincronizza abbonamenti, aspetto, orario dei promemoria e avatar. Puoi anche esportare un JSON.
- I promemoria sono notifiche locali. L’app pianifica più scadenze e aggiorna la coda all’apertura. Se non apri l’app a lungo, i promemoria successivi possono interrompersi per il limite di sistema.
- Include il Privacy Manifest e non traccia tra app.
""",
        "pt-BR": """
## Complemento (20 de agosto de 2026)

- O app exige iOS 18 ou posterior.
- Com iCloud, o app sincroniza assinaturas, aparência, horário do lembrete e avatar. Você também pode exportar um JSON.
- Lembretes são notificações locais. O app agenda várias datas futuras e atualiza a fila ao abrir. Se você não abrir o app por muito tempo, os próximos avisos podem parar por causa do limite do sistema.
- Inclui Privacy Manifest e não faz rastreamento entre apps.
""",
    },
    "terms": {
        "zh-Hant": """
## 補充說明（2026 年 8 月 20 日）

- 本應用程式需要 iOS 18 或更高版本。
- 預設不進行雲端即時同步。刪除應用前請自行匯出或備份。
- 續費提醒會預先安排未來若干期，並在打開應用時刷新。
""",
        "ja": """
## 追記（2026年8月20日）

- 本アプリは iOS 18 以降が必要です。
- クラウドへのリアルタイム同期は行いません。削除前に書き出しまたはバックアップしてください。
- 更新リマインダーは今後数回分を予約し、起動時に更新します。
""",
        "ko": """
## 추가 안내 (2026년 8월 20일)

- 이 앱은 iOS 18 이상이 필요합니다.
- 클라우드 실시간 동기화는 하지 않습니다. 삭제 전에 내보내거나 백업하세요.
- 갱신 알림은 앞으로 여러 회차를 예약하고 앱을 열 때 갱신됩니다.
""",
        "de": """
## Ergänzung (20. August 2026)

- Die App benötigt iOS 18 oder neuer.
- Es gibt keine Live-Cloud-Synchronisierung. Exportiere oder sichere Daten vor dem Löschen.
- Erinnerungen werden für mehrere künftige Zyklen geplant und beim Öffnen aktualisiert.
""",
        "fr": """
## Complément (20 août 2026)

- L’App nécessite iOS 18 ou une version ultérieure.
- Pas de synchronisation cloud en direct. Exportez ou sauvegardez avant de supprimer l’App.
- Les rappels sont planifiés pour plusieurs échéances et rafraîchis à l’ouverture.
""",
        "es": """
## Nota adicional (20 de agosto de 2026)

- La app requiere iOS 18 o posterior.
- No hay sincronización en la nube en vivo. Exporta o haz copia antes de borrar la app.
- Los recordatorios se programan para varios ciclos y se actualizan al abrir la app.
""",
        "it": """
## Integrazione (20 agosto 2026)

- L’app richiede iOS 18 o successivo.
- Non c’è sincronizzazione cloud in tempo reale. Esporta o fai backup prima di eliminare l’app.
- I promemoria sono pianificati per più cicli e aggiornati all’apertura.
""",
        "pt-BR": """
## Complemento (20 de agosto de 2026)

- O app exige iOS 18 ou posterior.
- Não há sincronização em nuvem em tempo real. Exporte ou faça backup antes de apagar o app.
- Os lembretes são agendados para vários ciclos e atualizados ao abrir o app.
""",
    },
}


def patch_markdown() -> None:
    for kind, prefix in (("privacy", "PrivacyPolicy"), ("terms", "TermsOfUse")):
        for code, *_ in LANGS:
            if code in ("en", "zh-Hans"):
                continue
            path = LEGAL / f"{prefix}-{code}.md"
            text = path.read_text(encoding="utf-8")
            for old, new in DATE_REPLACEMENTS:
                text = text.replace(old, new)
            marker = WEBSITE
            if marker not in text:
                block = WEBSITE_BLOCKS[kind][code]
                # insert after first blank line following the opening paragraphs
                parts = text.split("\n\n", 2)
                if len(parts) >= 2:
                    text = parts[0] + "\n\n" + parts[1] + "\n\n" + block + (parts[2] if len(parts) > 2 else "")
                else:
                    text = text.rstrip() + "\n\n" + block
            extra = EXTRA_SECTIONS[kind][code].strip() + "\n"
            heading = extra.splitlines()[0]
            if heading not in text:
                text = text.rstrip() + "\n\n" + extra
            path.write_text(text, encoding="utf-8")


def md_to_html(md: str) -> str:
    lines = md.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    in_list = False

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    def inline(text: str) -> str:
        text = html.escape(text)
        text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
        text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
        text = re.sub(
            r"\[([^\]]+)\]\((https?://[^)]+)\)",
            r'<a href="\2" rel="noopener">\1</a>',
            text,
        )
        text = re.sub(
            r"(https://[^\s<]+)",
            r'<a href="\1" rel="noopener">\1</a>',
            text,
        )
        return text

    paragraph: list[str] = []

    def flush_p() -> None:
        if paragraph:
            out.append("<p>" + "<br>\n".join(inline(p) for p in paragraph) + "</p>")
            paragraph.clear()

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            flush_p()
            close_list()
            continue
        heading = re.match(r"^(#{1,3})\s+(.*)$", line)
        if heading:
            flush_p()
            close_list()
            level = len(heading.group(1))
            out.append(f"<h{level}>{inline(heading.group(2))}</h{level}>")
            continue
        bullet = re.match(r"^- (.*)$", line)
        if bullet:
            flush_p()
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(bullet.group(1))}</li>")
            continue
        close_list()
        paragraph.append(line.rstrip("  "))
    flush_p()
    close_list()
    return "\n".join(out)


PAGE_CSS = """
:root { color-scheme: light dark; --bg: #f6f4f1; --card: #fff; --ink: #1c1917; --muted: #57534e; --line: #e7e5e4; --accent: #0f766e; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #1c1917; --card: #292524; --ink: #fafaf9; --muted: #a8a29e; --line: #44403c; --accent: #5eead4; }
}
* { box-sizing: border-box; }
body { margin: 0; font: 17px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: var(--bg); color: var(--ink); }
header, main, footer { max-width: 760px; margin: 0 auto; padding: 24px 20px; }
header { display: flex; flex-wrap: wrap; gap: 12px 20px; align-items: baseline; justify-content: space-between; }
a { color: var(--accent); }
.brand { font-weight: 700; text-decoration: none; color: inherit; font-size: 20px; }
nav { display: flex; flex-wrap: wrap; gap: 12px; }
.card { background: var(--card); border: 1px solid var(--line); border-radius: 16px; padding: 28px 24px 36px; }
h1 { font-size: 28px; line-height: 1.25; margin: 0 0 8px; }
h2 { font-size: 20px; margin-top: 1.6em; }
h3 { font-size: 17px; margin-top: 1.2em; }
.muted { color: var(--muted); }
.langs { display: flex; flex-wrap: wrap; gap: 8px; margin: 16px 0 24px; }
.langs a { display: inline-block; padding: 6px 10px; border-radius: 999px; border: 1px solid var(--line); text-decoration: none; color: inherit; font-size: 13px; }
.langs a[aria-current="page"] { background: var(--ink); color: var(--bg); border-color: transparent; }
ul { padding-left: 1.2em; }
code { font-size: 0.92em; }
.grid { display: grid; gap: 16px; }
@media (min-width: 640px) { .grid { grid-template-columns: 1fr 1fr; } }
.tile { display: block; background: var(--card); border: 1px solid var(--line); border-radius: 16px; padding: 20px; text-decoration: none; color: inherit; }
.tile strong { display: block; margin-bottom: 6px; }
footer { color: var(--muted); font-size: 14px; }
"""


def page(title: str, body: str, extra_head: str = "") -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{PAGE_CSS}</style>
{extra_head}
</head>
<body>
{body}
</body>
</html>
"""


def lang_nav(kind: str, current: str) -> str:
    links = []
    for code, label, *_ in LANGS:
        current_attr = ' aria-current="page"' if code == current else ""
        links.append(f'<a href="./{code}.html"{current_attr}>{html.escape(label)}</a>')
    return '<div class="langs">' + "".join(links) + "</div>"


def site_nav(current: str, prefix: str = "../") -> str:
    items = [
        ("privacy", "Privacy"),
        ("terms", "Terms"),
        ("support", "Support"),
    ]
    links = []
    for slug, label in items:
        href = f"{prefix}{slug}/"
        if slug == current:
            links.append(f"<strong>{html.escape(label)}</strong>")
        else:
            links.append(f'<a href="{href}">{html.escape(label)}</a>')
    return "<nav>" + " · ".join(links) + "</nav>"


def redirect_index(fallback_title: str) -> str:
    return page(
        fallback_title,
        """<p>Redirecting…</p>
<script>
const map = {'zh-CN':'zh-Hans','zh-SG':'zh-Hans','zh-TW':'zh-Hant','zh-HK':'zh-Hant','zh-MO':'zh-Hant','zh-Hant':'zh-Hant','zh':'zh-Hans','ja':'ja','ko':'ko','de':'de','fr':'fr','es':'es','it':'it','pt':'pt-BR','pt-BR':'pt-BR'};
const tag = (navigator.languages && navigator.languages[0] || navigator.language || 'en');
let code = 'en';
for (const [prefix, value] of Object.entries(map)) {
  if (tag.toLowerCase().startsWith(prefix.toLowerCase())) { code = value; break; }
}
location.replace('./' + code + '.html');
</script>
<noscript><a href="./en.html">English</a></noscript>""",
    )


def document_page(kind: str, code: str, native_title: str, markdown: str) -> str:
    body_html = md_to_html(markdown)
    inner = f"""
<header>
  <a class="brand" href="../">Renewity</a>
  {site_nav(kind)}
</header>
<main>
  <div class="card">
    {lang_nav(kind, code)}
    {body_html}
  </div>
</main>
<footer>Renewity · {SUPPORT_EMAIL}</footer>
"""
    return page(f"{native_title} · Renewity", inner)


def write_support_markdown() -> None:
    for code, markdown in SUPPORT_MD.items():
        (LEGAL / f"Support-{code}.md").write_text(markdown.strip() + "\n", encoding="utf-8")


def build_pages() -> None:
    (DOCS / "privacy").mkdir(parents=True, exist_ok=True)
    (DOCS / "terms").mkdir(parents=True, exist_ok=True)
    (DOCS / "support").mkdir(parents=True, exist_ok=True)
    (DOCS / ".nojekyll").write_text("", encoding="utf-8")

    for kind, prefix, fallback_title in (
        ("privacy", "PrivacyPolicy", "Privacy Policy"),
        ("terms", "TermsOfUse", "Terms of Use"),
        ("support", "Support", "Support"),
    ):
        for code, _label, privacy_title, terms_title in LANGS:
            if kind == "privacy":
                native = privacy_title
            elif kind == "terms":
                native = terms_title
            else:
                native = SUPPORT_TITLES[code]
            md = (LEGAL / f"{prefix}-{code}.md").read_text(encoding="utf-8")
            (DOCS / kind / f"{code}.html").write_text(
                document_page(kind, code, native, md), encoding="utf-8"
            )
        (DOCS / kind / "index.html").write_text(redirect_index(fallback_title), encoding="utf-8")

    tiles = "".join(
        f'<a class="tile" href="./privacy/{code}.html"><strong>{html.escape(label)}</strong>'
        f'<span class="muted">{html.escape(p)} · {html.escape(t)} · {html.escape(SUPPORT_TITLES[code])}</span></a>'
        for code, label, p, t in LANGS
    )
    index_body = f"""
<header>
  <a class="brand" href="./">Renewity</a>
  {site_nav("", "./")}
</header>
<main>
  <h1>Renewity</h1>
  <p class="muted">Privacy Policy, Terms of Use, and Support. Enable GitHub Pages with the <code>docs</code> folder.</p>
  <p><a href="./privacy/">Privacy Policy</a> · <a href="./terms/">Terms of Use</a> · <a href="./support/">Support</a></p>
  <h2>Languages</h2>
  <div class="grid">{tiles}</div>
</main>
<footer>Questions: {SUPPORT_EMAIL}</footer>
"""
    (DOCS / "index.html").write_text(page("Renewity", index_body), encoding="utf-8")
    (DOCS / "README.md").write_text(
        f"""# GitHub Pages 文档

这个 `docs/` 目录可以直接作为 GitHub Pages 站点发布，内容与应用内《隐私政策》《使用条款》以及支持页一致。

## 发布步骤

1. 把仓库推送到 GitHub（建议仓库名 `Renewity`）。
2. 打开仓库 **Settings → Pages**。
3. Build and deployment 选 **Deploy from a branch**。
4. Branch 选 `main`，文件夹选 `/docs`，保存。
5. 几分钟后打开：`{WEBSITE}/`

App Store Connect 技术支持网址填：`{WEBSITE}/support/`

如果 GitHub 用户名不是 `LiuZheng1999`，或仓库名不是 `Renewity`，请同时改：

- `Renewity/Utilities/AppConfig.swift` 里的 `legalWebsiteURL`
- `Renewity/Legal/` 下各语言文档中的网址
- 然后重新运行 `python3 scripts/build_legal_pages.py`

应用设置里的「隐私政策」「使用条款」「支持网页」会打开上述地址。
""",
        encoding="utf-8",
    )


def main() -> None:
    write_support_markdown()
    patch_markdown()
    build_pages()
    print("legal pages written to", DOCS)


if __name__ == "__main__":
    main()
