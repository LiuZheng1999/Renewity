#!/usr/bin/env python3
"""Fill missing Localizable / InfoPlist string catalog translations."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGS = ["en", "zh-Hant", "ja", "ko", "de", "fr", "es", "it", "pt-BR"]


def same(value: str) -> dict[str, str]:
    return {lang: value for lang in LANGS}


# source (zh-Hans) -> translations
TRANSLATIONS: dict[str, dict[str, str]] = {
    "·": {
        "en": "·", "zh-Hant": "·", "ja": "·", "ko": "·", "de": "·",
        "fr": "·", "es": "·", "it": "·", "pt-BR": "·",
    },
    "paywall.price.perYear": {
        "en": "/yr", "zh-Hant": "/年", "ja": "/年", "ko": "/년", "de": "/Jahr",
        "fr": "/an", "es": "/año", "it": "/anno", "pt-BR": "/ano",
    },
    "paywall.price.perMonth": {
        "en": "/mo", "zh-Hant": "/月", "ja": "/月", "ko": "/월", "de": "/Monat",
        "fr": "/mois", "es": "/mes", "it": "/mese", "pt-BR": "/mês",
    },
    "%@ / %@": {
        "en": "%@ / %@", "zh-Hant": "%@ / %@", "ja": "%@ / %@", "ko": "%@ / %@",
        "de": "%@ / %@", "fr": "%@ / %@", "es": "%@ / %@", "it": "%@ / %@", "pt-BR": "%@ / %@",
    },
    "%@ 即将到来": {
        "en": "%@ upcoming", "zh-Hant": "%@ 即將到來", "ja": "%@ がまもなく",
        "ko": "%@ 예정", "de": "%@ stehen an", "fr": "%@ à venir",
        "es": "%@ próximos", "it": "%@ in arrivo", "pt-BR": "%@ em breve",
    },
    "%@ 总计": {
        "en": "%@ total", "zh-Hant": "%@ 總計", "ja": "合計 %@",
        "ko": "합계 %@", "de": "%@ insgesamt", "fr": "%@ au total",
        "es": "%@ en total", "it": "%@ in totale", "pt-BR": "%@ no total",
    },
    "%@，%@": {
        "en": "%@, %@", "zh-Hant": "%@，%@", "ja": "%@、%@", "ko": "%@, %@",
        "de": "%@, %@", "fr": "%@, %@", "es": "%@, %@", "it": "%@, %@", "pt-BR": "%@, %@",
    },
    "%lld": {
        "en": "%lld", "zh-Hant": "%lld", "ja": "%lld", "ko": "%lld", "de": "%lld",
        "fr": "%lld", "es": "%lld", "it": "%lld", "pt-BR": "%lld",
    },
    "%lld:00": {
        "en": "%lld:00", "zh-Hant": "%lld:00", "ja": "%lld:00", "ko": "%lld:00",
        "de": "%lld:00", "fr": "%lld:00", "es": "%lld:00", "it": "%lld:00", "pt-BR": "%lld:00",
    },
    "+%lld": {
        "en": "+%lld", "zh-Hant": "+%lld", "ja": "+%lld", "ko": "+%lld", "de": "+%lld",
        "fr": "+%lld", "es": "+%lld", "it": "+%lld", "pt-BR": "+%lld",
    },
    "0.00": {
        "en": "0.00", "zh-Hant": "0.00", "ja": "0.00", "ko": "0.00", "de": "0.00",
        "fr": "0.00", "es": "0.00", "it": "0.00", "pt-BR": "0.00",
    },
    "American Express": same("American Express"),
    "Apple Pay": same("Apple Pay"),
    "Google Pay": same("Google Pay"),
    "Mastercard": same("Mastercard"),
    "PayPal": same("PayPal"),
    "Pro": same("Pro"),
    "Visa": same("Visa"),
    "一次买断": {
        "en": "One-time purchase", "zh-Hant": "一次買斷", "ja": "買い切り",
        "ko": "평생 구매", "de": "Einmalkauf", "fr": "Achat unique",
        "es": "Pago único", "it": "Acquisto una tantum", "pt-BR": "Compra única",
    },
    "上个月": {
        "en": "Previous month", "zh-Hant": "上個月", "ja": "前月",
        "ko": "지난달", "de": "Vorheriger Monat", "fr": "Mois précédent",
        "es": "Mes anterior", "it": "Mese precedente", "pt-BR": "Mês anterior",
    },
    "上次更新": {
        "en": "Last updated", "zh-Hant": "上次更新", "ja": "前回の更新",
        "ko": "마지막 업데이트", "de": "Zuletzt aktualisiert", "fr": "Dernière mise à jour",
        "es": "Última actualización", "it": "Ultimo aggiornamento", "pt-BR": "Última atualização",
    },
    "下个月": {
        "en": "Next month", "zh-Hant": "下個月", "ja": "翌月",
        "ko": "다음달", "de": "Nächster Monat", "fr": "Mois suivant",
        "es": "Mes siguiente", "it": "Mese successivo", "pt-BR": "Próximo mês",
    },
    "两周": {
        "en": "2 weeks", "zh-Hant": "兩週", "ja": "2週間",
        "ko": "2주", "de": "Zwei Wochen", "fr": "Deux semaines",
        "es": "Dos semanas", "it": "Due settimane", "pt-BR": "Duas semanas",
    },
    "今天 %@": {
        "en": "Today %@", "zh-Hant": "今天 %@", "ja": "今日 %@",
        "ko": "오늘 %@", "de": "Heute %@", "fr": "Aujourd’hui %@",
        "es": "Hoy %@", "it": "Oggi %@", "pt-BR": "Hoje %@",
    },
    "今天已经更新过汇率": {
        "en": "Rates were already updated today", "zh-Hant": "今天已經更新過匯率",
        "ja": "為替レートは本日すでに更新済みです", "ko": "환율은 오늘 이미 업데이트되었습니다",
        "de": "Kurse wurden heute bereits aktualisiert", "fr": "Les taux ont déjà été mis à jour aujourd’hui",
        "es": "Los tipos ya se actualizaron hoy", "it": "I tassi sono già stati aggiornati oggi",
        "pt-BR": "As taxas já foram atualizadas hoje",
    },
    "从相册选择": {
        "en": "Choose from Photos", "zh-Hant": "從相簿選擇", "ja": "写真から選択",
        "ko": "사진에서 선택", "de": "Aus Fotos wählen", "fr": "Choisir dans Photos",
        "es": "Elegir de Fotos", "it": "Scegli da Foto", "pt-BR": "Escolher nas Fotos",
    },
    "例如：公司卡、家庭账户": {
        "en": "e.g. Company card, Family account", "zh-Hant": "例如：公司卡、家庭帳戶",
        "ja": "例：会社のカード、家族アカウント", "ko": "예: 회사 카드, 가족 계정",
        "de": "z. B. Firmenkarte, Familienkonto", "fr": "p. ex. carte pro, compte familial",
        "es": "p. ej. tarjeta de empresa, cuenta familiar", "it": "es. carta aziendale, account famiglia",
        "pt-BR": "ex.: cartão da empresa, conta da família",
    },
    "信用卡": {
        "en": "Credit card", "zh-Hant": "信用卡", "ja": "クレジットカード",
        "ko": "신용카드", "de": "Kreditkarte", "fr": "Carte de crédit",
        "es": "Tarjeta de crédito", "it": "Carta di credito", "pt-BR": "Cartão de crédito",
    },
    "借记卡": {
        "en": "Debit card", "zh-Hant": "簽帳卡", "ja": "デビットカード",
        "ko": "체크카드", "de": "Debitkarte", "fr": "Carte de débit",
        "es": "Tarjeta de débito", "it": "Carta di debito", "pt-BR": "Cartão de débito",
    },
    "免费版 %lld 次，Pro 最多 %lld 次": {
        "en": "Free: %lld; Pro: up to %lld", "zh-Hant": "免費版 %lld 次，Pro 最多 %lld 次",
        "ja": "無料は %lld 件、Pro は最大 %lld 件", "ko": "무료 %lld회, Pro 최대 %lld회",
        "de": "Gratis: %lld; Pro: bis zu %lld", "fr": "Gratuit : %lld ; Pro : jusqu’à %lld",
        "es": "Gratis: %lld; Pro: hasta %lld", "it": "Gratis: %lld; Pro: fino a %lld",
        "pt-BR": "Grátis: %lld; Pro: até %lld",
    },
    "半年": {
        "en": "6 months", "zh-Hant": "半年", "ja": "半年",
        "ko": "6개월", "de": "Halbjahr", "fr": "Semestre",
        "es": "Semestre", "it": "Semestre", "pt-BR": "Semestre",
    },
    "单位": {
        "en": "Unit", "zh-Hant": "單位", "ja": "単位",
        "ko": "단위", "de": "Einheit", "fr": "Unité",
        "es": "Unidad", "it": "Unità", "pt-BR": "Unidade",
    },
    "和": {
        "en": " and ", "zh-Hant": "和", "ja": "と",
        "ko": " 및 ", "de": " und ", "fr": " et ",
        "es": " y ", "it": " e ", "pt-BR": " e ",
    },
    "天": {
        "en": "days", "zh-Hant": "天", "ja": "日",
        "ko": "일", "de": "Tage", "fr": "jours",
        "es": "días", "it": "giorni", "pt-BR": "dias",
    },
    "好": {
        "en": "OK", "zh-Hant": "好", "ja": "OK",
        "ko": "확인", "de": "OK", "fr": "OK",
        "es": "OK", "it": "OK", "pt-BR": "OK",
    },
    "将用 iCloud 备份覆盖现有订阅、自定义分类和自定义支付方式，此操作无法撤销。": {
        "en": "This replaces your current subscriptions, custom categories, and custom payment methods with the iCloud backup. This can’t be undone.",
        "zh-Hant": "將用 iCloud 備份覆蓋現有訂閱、自訂分類和自訂支付方式，此操作無法復原。",
        "ja": "iCloud バックアップで現在のサブスク、カスタムカテゴリ、カスタム支払い方法を上書きします。元に戻せません。",
        "ko": "iCloud 백업으로 현재 구독, 사용자 지정 분류, 사용자 지정 결제 수단을 덮어씁니다. 되돌릴 수 없습니다.",
        "de": "Das iCloud-Backup ersetzt aktuelle Abos, eigene Kategorien und Zahlungsmethoden. Das kann nicht rückgängig gemacht werden.",
        "fr": "La sauvegarde iCloud remplacera vos abonnements, catégories et moyens de paiement personnalisés. Action irréversible.",
        "es": "La copia de iCloud sustituirá tus suscripciones, categorías y métodos de pago personalizados. No se puede deshacer.",
        "it": "Il backup iCloud sostituirà abbonamenti, categorie e metodi di pagamento personalizzati. L’operazione non è reversibile.",
        "pt-BR": "O backup do iCloud substituirá assinaturas, categorias e formas de pagamento personalizadas. Isso não pode ser desfeito.",
    },
    "尚未更新": {
        "en": "Not updated yet", "zh-Hant": "尚未更新", "ja": "未更新",
        "ko": "아직 업데이트되지 않음", "de": "Noch nicht aktualisiert", "fr": "Pas encore mis à jour",
        "es": "Aún no actualizado", "it": "Non ancora aggiornato", "pt-BR": "Ainda não atualizado",
    },
    "已经购买过？": {
        "en": "Already purchased? ", "zh-Hant": "已經購買過？", "ja": "購入済みですか？",
        "ko": "이미 구매하셨나요?", "de": "Bereits gekauft? ", "fr": "Déjà acheté ? ",
        "es": "¿Ya lo compraste? ", "it": "Hai già acquistato? ", "pt-BR": "Já comprou? ",
    },
    "币种": {
        "en": "Currency", "zh-Hant": "幣種", "ja": "通貨",
        "ko": "통화", "de": "Währung", "fr": "Devise",
        "es": "Moneda", "it": "Valuta", "pt-BR": "Moeda",
    },
    "常用货币": {
        "en": "Common currencies", "zh-Hant": "常用貨幣", "ja": "よく使う通貨",
        "ko": "자주 쓰는 통화", "de": "Häufige Währungen", "fr": "Devises courantes",
        "es": "Monedas frecuentes", "it": "Valute comuni", "pt-BR": "Moedas comuns",
    },
    "年化 %@ | %@": {
        "en": "Yearly %@ | %@", "zh-Hant": "年化 %@ | %@", "ja": "年額 %@ | %@",
        "ko": "연간 %@ | %@", "de": "Jährlich %@ | %@", "fr": "Annuel %@ | %@",
        "es": "Anual %@ | %@", "it": "Annuale %@ | %@", "pt-BR": "Anual %@ | %@",
    },
    "年化 %@ | 换算为其他货币": {
        "en": "Yearly %@ | Convert to another currency", "zh-Hant": "年化 %@ | 換算為其他貨幣",
        "ja": "年額 %@ | 別の通貨に換算", "ko": "연간 %@ | 다른 통화로 환산",
        "de": "Jährlich %@ | In andere Währung umrechnen", "fr": "Annuel %@ | Convertir dans une autre devise",
        "es": "Anual %@ | Convertir a otra moneda", "it": "Annuale %@ | Converti in un’altra valuta",
        "pt-BR": "Anual %@ | Converter para outra moeda",
    },
    "总览、分类合计和小组件会按参考汇率换算到此货币，仅供参考，不会改写各笔订阅记下的金额。": {
        "en": "Overview, category totals, and widgets convert into this currency using reference rates. Amounts you recorded for each subscription stay unchanged.",
        "zh-Hant": "總覽、分類合計和小組件會按參考匯率換算到此貨幣，僅供參考，不會改寫各筆訂閱記下的金額。",
        "ja": "概要、カテゴリ合計、ウィジェットはこの参考レートで換算されます。各サブスクに記録した金額は変わりません。",
        "ko": "개요, 분류 합계, 위젯은 참고 환율로 이 통화로 환산됩니다. 각 구독에 기록한 금액은 바뀌지 않습니다.",
        "de": "Übersicht, Kategorie-Summen und Widgets rechnen mit Referenzkursen in diese Währung um. Die erfassten Beträge bleiben unverändert.",
        "fr": "L’aperçu, les totaux par catégorie et les widgets sont convertis avec des taux de référence. Les montants saisis ne changent pas.",
        "es": "El resumen, los totales por categoría y los widgets se convierten con tipos de referencia. Los importes guardados no cambian.",
        "it": "Panoramica, totali per categoria e widget sono convertiti con tassi di riferimento. Gli importi registrati non cambiano.",
        "pt-BR": "Visão geral, totais por categoria e widgets são convertidos com taxas de referência. Os valores registrados não mudam.",
    },
    "恢复后将覆盖现有订阅、自定义分类和自定义支付方式，此操作无法撤销。": {
        "en": "Restore will replace your current subscriptions, custom categories, and custom payment methods. This can’t be undone.",
        "zh-Hant": "恢復後將覆蓋現有訂閱、自訂分類和自訂支付方式，此操作無法復原。",
        "ja": "復元すると現在のサブスク、カスタムカテゴリ、カスタム支払い方法が上書きされます。元に戻せません。",
        "ko": "복원하면 현재 구독, 사용자 지정 분류, 사용자 지정 결제 수단이 덮어씌워집니다. 되돌릴 수 없습니다.",
        "de": "Wiederherstellen ersetzt aktuelle Abos, eigene Kategorien und Zahlungsmethoden. Das kann nicht rückgängig gemacht werden.",
        "fr": "La restauration remplacera vos abonnements, catégories et moyens de paiement personnalisés. Action irréversible.",
        "es": "La restauración sustituirá tus suscripciones, categorías y métodos de pago personalizados. No se puede deshacer.",
        "it": "Il ripristino sostituirà abbonamenti, categorie e metodi di pagamento personalizzati. L’operazione non è reversibile.",
        "pt-BR": "A restauração substituirá assinaturas, categorias e formas de pagamento personalizadas. Isso não pode ser desfeito.",
    },
    "所有货币": {
        "en": "All currencies", "zh-Hant": "所有貨幣", "ja": "すべての通貨",
        "ko": "모든 통화", "de": "Alle Währungen", "fr": "Toutes les devises",
        "es": "Todas las monedas", "it": "Tutte le valute", "pt-BR": "Todas as moedas",
    },
    "扣费货币": {
        "en": "Billing currency", "zh-Hant": "扣費貨幣", "ja": "請求通貨",
        "ko": "결제 통화", "de": "Abrechnungswährung", "fr": "Devise de facturation",
        "es": "Moneda de cobro", "it": "Valuta di addebito", "pt-BR": "Moeda de cobrança",
    },
    "换算为其他货币": {
        "en": "Convert to another currency", "zh-Hant": "換算為其他貨幣", "ja": "別の通貨に換算",
        "ko": "다른 통화로 환산", "de": "In andere Währung umrechnen", "fr": "Convertir dans une autre devise",
        "es": "Convertir a otra moneda", "it": "Converti in un’altra valuta", "pt-BR": "Converter para outra moeda",
    },
    "提示": {
        "en": "Notice", "zh-Hant": "提示", "ja": "お知らせ",
        "ko": "알림", "de": "Hinweis", "fr": "Info",
        "es": "Aviso", "it": "Avviso", "pt-BR": "Aviso",
    },
    "搜索货币": {
        "en": "Search currencies", "zh-Hant": "搜尋貨幣", "ja": "通貨を検索",
        "ko": "통화 검색", "de": "Währung suchen", "fr": "Rechercher une devise",
        "es": "Buscar moneda", "it": "Cerca valuta", "pt-BR": "Buscar moeda",
    },
    "支付方式": {
        "en": "Payment method", "zh-Hant": "支付方式", "ja": "支払い方法",
        "ko": "결제 수단", "de": "Zahlungsmethode", "fr": "Moyen de paiement",
        "es": "Método de pago", "it": "Metodo di pagamento", "pt-BR": "Forma de pagamento",
    },
    "改默认货币、扣费货币，并把合计换算到其他货币": {
        "en": "Change display and billing currencies, and convert totals",
        "zh-Hant": "改預設貨幣、扣費貨幣，並把合計換算到其他貨幣",
        "ja": "表示通貨・請求通貨を変更し、合計を換算",
        "ko": "기본 통화와 결제 통화를 바꾸고 합계를 환산",
        "de": "Anzeige- und Abrechnungswährung ändern und Summen umrechnen",
        "fr": "Changer les devises d’affichage et de facturation, et convertir les totaux",
        "es": "Cambiar moneda de visualización y cobro, y convertir totales",
        "it": "Cambia valuta di visualizzazione e addebito e converti i totali",
        "pt-BR": "Alterar moedas de exibição e cobrança e converter totais",
    },
    "新建": {
        "en": "New", "zh-Hant": "新增", "ja": "新規",
        "ko": "새로 만들기", "de": "Neu", "fr": "Nouveau",
        "es": "Nuevo", "it": "Nuovo", "pt-BR": "Novo",
    },
    "新建支付方式": {
        "en": "New payment method", "zh-Hant": "新增支付方式", "ja": "支払い方法を追加",
        "ko": "결제 수단 추가", "de": "Neue Zahlungsmethode", "fr": "Nouveau moyen de paiement",
        "es": "Nuevo método de pago", "it": "Nuovo metodo di pagamento", "pt-BR": "Nova forma de pagamento",
    },
    "新支付方式": {
        "en": "New payment method", "zh-Hant": "新支付方式", "ja": "新しい支払い方法",
        "ko": "새 결제 수단", "de": "Neue Zahlungsmethode", "fr": "Nouveau moyen de paiement",
        "es": "Nuevo método de pago", "it": "Nuovo metodo di pagamento", "pt-BR": "Nova forma de pagamento",
    },
    "无法更新": {
        "en": "Couldn’t update", "zh-Hant": "無法更新", "ja": "更新できません",
        "ko": "업데이트할 수 없음", "de": "Aktualisierung fehlgeschlagen", "fr": "Mise à jour impossible",
        "es": "No se pudo actualizar", "it": "Impossibile aggiornare", "pt-BR": "Não foi possível atualizar",
    },
    "无法获取最新汇率": {
        "en": "Couldn’t fetch the latest rates", "zh-Hant": "無法取得最新匯率",
        "ja": "最新の為替レートを取得できません", "ko": "최신 환율을 가져올 수 없습니다",
        "de": "Aktuelle Kurse konnten nicht geladen werden", "fr": "Impossible d’obtenir les derniers taux",
        "es": "No se pudieron obtener los tipos más recientes", "it": "Impossibile ottenere i tassi più recenti",
        "pt-BR": "Não foi possível obter as taxas mais recentes",
    },
    "无限订阅、多货币和云备份": {
        "en": "Unlimited subscriptions, multiple currencies, and cloud backup",
        "zh-Hant": "無限訂閱、多貨幣和雲端備份",
        "ja": "無制限のサブスク、複数通貨、クラウドバックアップ",
        "ko": "무제한 구독, 다중 통화, 클라우드 백업",
        "de": "Unbegrenzte Abos, mehrere Währungen und Cloud-Backup",
        "fr": "Abonnements illimités, multi-devises et sauvegarde cloud",
        "es": "Suscripciones ilimitadas, varias monedas y copia en la nube",
        "it": "Abbonamenti illimitati, più valute e backup cloud",
        "pt-BR": "Assinaturas ilimitadas, várias moedas e backup na nuvem",
    },
    "日历": {
        "en": "Calendar", "zh-Hant": "日曆", "ja": "カレンダー",
        "ko": "캘린더", "de": "Kalender", "fr": "Calendrier",
        "es": "Calendario", "it": "Calendario", "pt-BR": "Calendário",
    },
    "昨天 %@": {
        "en": "Yesterday %@", "zh-Hant": "昨天 %@", "ja": "昨日 %@",
        "ko": "어제 %@", "de": "Gestern %@", "fr": "Hier %@",
        "es": "Ayer %@", "it": "Ieri %@", "pt-BR": "Ontem %@",
    },
    "暂停后不再按期扣费，也不会发送提醒。": {
        "en": "While paused, it won’t count as a charge and reminders won’t be sent.",
        "zh-Hant": "暫停後不再按期扣費，也不會發送提醒。",
        "ja": "一時停止中は請求もリマインダーも行われません。",
        "ko": "일시 중지하면 정기 결제가 잡히지 않고 알림도 보내지 않습니다.",
        "de": "Im Pause-Status gibt es keine fällige Abbuchung und keine Erinnerungen.",
        "fr": "En pause, aucun prélèvement ni rappel n’est prévu.",
        "es": "En pausa no se cuenta un cobro ni se envían recordatorios.",
        "it": "In pausa non risultano addebiti e non partono promemoria.",
        "pt-BR": "Em pausa, não há cobrança prevista nem lembretes.",
    },
    "暂时无法连接到 App Store": {
        "en": "Can’t connect to the App Store right now",
        "zh-Hant": "暫時無法連接到 App Store",
        "ja": "現在 App Store に接続できません",
        "ko": "지금은 App Store에 연결할 수 없습니다",
        "de": "Keine Verbindung zum App Store möglich",
        "fr": "Connexion à l’App Store impossible pour le moment",
        "es": "No se puede conectar a App Store ahora",
        "it": "Impossibile connettersi all’App Store al momento",
        "pt-BR": "Não foi possível conectar à App Store agora",
    },
    "更新汇率": {
        "en": "Update rates", "zh-Hant": "更新匯率", "ja": "レートを更新",
        "ko": "환율 업데이트", "de": "Kurse aktualisieren", "fr": "Mettre à jour les taux",
        "es": "Actualizar tipos", "it": "Aggiorna tassi", "pt-BR": "Atualizar taxas",
    },
    "有 %lld 笔金额暂时无法换算，未计入合计。": {
        "en": "%lld amounts couldn’t be converted and were left out of the total.",
        "zh-Hant": "有 %lld 筆金額暫時無法換算，未計入合計。",
        "ja": "%lld 件は換算できず、合計に含まれていません。",
        "ko": "%lld건은 환산하지 못해 합계에서 빠졌습니다.",
        "de": "%lld Beträge konnten nicht umgerechnet werden und fehlen in der Summe.",
        "fr": "%lld montants n’ont pas pu être convertis et sont exclus du total.",
        "es": "%lld importes no se pudieron convertir y no entran en el total.",
        "it": "%lld importi non convertibili sono esclusi dal totale.",
        "pt-BR": "%lld valores não puderam ser convertidos e ficaram de fora do total.",
    },
    "未命名订阅": {
        "en": "Untitled subscription", "zh-Hant": "未命名訂閱", "ja": "無題のサブスク",
        "ko": "제목 없는 구독", "de": "Unbenanntes Abo", "fr": "Abonnement sans titre",
        "es": "Suscripción sin nombre", "it": "Abbonamento senza nome", "pt-BR": "Assinatura sem nome",
    },
    "本月支出选项": {
        "en": "This month’s spending options", "zh-Hant": "本月支出選項", "ja": "今月の支出オプション",
        "ko": "이번 달 지출 옵션", "de": "Optionen für Monatsausgaben", "fr": "Options des dépenses du mois",
        "es": "Opciones del gasto de este mes", "it": "Opzioni spesa del mese", "pt-BR": "Opções dos gastos do mês",
    },
    "正在加载套餐": {
        "en": "Loading plans", "zh-Hant": "正在載入方案", "ja": "プランを読み込み中",
        "ko": "요금제 불러오는 중", "de": "Tarife werden geladen", "fr": "Chargement des formules",
        "es": "Cargando planes", "it": "Caricamento dei piani", "pt-BR": "Carregando planos",
    },
    "每 %lld %@": {
        "en": "Every %lld %@", "zh-Hant": "每 %lld %@", "ja": "%lld %@ごと",
        "ko": "%lld %@마다", "de": "Alle %lld %@", "fr": "Tous les %lld %@",
        "es": "Cada %lld %@", "it": "Ogni %lld %@", "pt-BR": "A cada %lld %@",
    },
    "每 5 天自动更新一次汇率，你也可以每天手动更新。": {
        "en": "Rates refresh automatically every 5 days. You can also update them once a day.",
        "zh-Hant": "每 5 天自動更新一次匯率，你也可以每天手動更新。",
        "ja": "為替レートは 5 日ごとに自動更新されます。1 日 1 回手動更新もできます。",
        "ko": "환율은 5일마다 자동 업데이트되며, 하루에 한 번 수동으로도 갱신할 수 있습니다.",
        "de": "Kurse werden alle 5 Tage automatisch aktualisiert. Manuell höchstens einmal pro Tag.",
        "fr": "Les taux se mettent à jour automatiquement tous les 5 jours. Vous pouvez aussi le faire une fois par jour.",
        "es": "Los tipos se actualizan solos cada 5 días. También puedes actualizarlos una vez al día.",
        "it": "I tassi si aggiornano automaticamente ogni 5 giorni. Puoi anche aggiornarli una volta al giorno.",
        "pt-BR": "As taxas atualizam automaticamente a cada 5 dias. Você também pode atualizar uma vez por dia.",
    },
    "每两周": {
        "en": "Every 2 weeks", "zh-Hant": "每兩週", "ja": "2週間ごと",
        "ko": "2주마다", "de": "Alle zwei Wochen", "fr": "Toutes les deux semaines",
        "es": "Cada dos semanas", "it": "Ogni due settimane", "pt-BR": "A cada duas semanas",
    },
    "每半年": {
        "en": "Every 6 months", "zh-Hant": "每半年", "ja": "半年ごと",
        "ko": "6개월마다", "de": "Alle sechs Monate", "fr": "Tous les six mois",
        "es": "Cada seis meses", "it": "Ogni sei mesi", "pt-BR": "A cada seis meses",
    },
    "每隔 %lld %@": {
        "en": "Every %lld %@", "zh-Hant": "每隔 %lld %@", "ja": "%lld %@ごと",
        "ko": "%lld %@마다", "de": "Alle %lld %@", "fr": "Tous les %lld %@",
        "es": "Cada %lld %@", "it": "Ogni %lld %@", "pt-BR": "A cada %lld %@",
    },
    "汇率": {
        "en": "Exchange rates", "zh-Hant": "匯率", "ja": "為替レート",
        "ko": "환율", "de": "Wechselkurse", "fr": "Taux de change",
        "es": "Tipos de cambio", "it": "Tassi di cambio", "pt-BR": "Taxas de câmbio",
    },
    "添加更多提醒": {
        "en": "Add another reminder", "zh-Hant": "新增更多提醒", "ja": "リマインダーを追加",
        "ko": "알림 추가", "de": "Weitere Erinnerung", "fr": "Ajouter un rappel",
        "es": "Añadir otro recordatorio", "it": "Aggiungi un promemoria", "pt-BR": "Adicionar outro lembrete",
    },
    "继续即表示你同意": {
        "en": "By continuing, you agree to the ", "zh-Hant": "繼續即表示你同意",
        "ja": "続けると、次に同意したことになります：", "ko": "계속하면 다음에 동의하게 됩니다: ",
        "de": "Wenn du fortfährst, stimmst du Folgendem zu: ", "fr": "En continuant, vous acceptez ",
        "es": "Al continuar, aceptas ", "it": "Continuando accetti ", "pt-BR": "Ao continuar, você concorda com ",
    },
    "背景色": {
        "en": "Background color", "zh-Hant": "背景色", "ja": "背景色",
        "ko": "배경색", "de": "Hintergrundfarbe", "fr": "Couleur d’arrière-plan",
        "es": "Color de fondo", "it": "Colore di sfondo", "pt-BR": "Cor de fundo",
    },
    "订阅名称": {
        "en": "Subscription name", "zh-Hant": "訂閱名稱", "ja": "サブスク名",
        "ko": "구독 이름", "de": "Abo-Name", "fr": "Nom de l’abonnement",
        "es": "Nombre de la suscripción", "it": "Nome dell’abbonamento", "pt-BR": "Nome da assinatura",
    },
    "订阅周期": {
        "en": "Billing cycle", "zh-Hant": "訂閱週期", "ja": "請求サイクル",
        "ko": "결제 주기", "de": "Abrechnungszyklus", "fr": "Périodicité",
        "es": "Ciclo de facturación", "it": "Ciclo di fatturazione", "pt-BR": "Ciclo de cobrança",
    },
    "试用持续到下次扣费日，当天开始按上面的费用扣款。": {
        "en": "The trial lasts until the next charge date. Billing at the amount above starts that day.",
        "zh-Hant": "試用持續到下次扣費日，當天開始按上面的費用扣款。",
        "ja": "無料期間は次回請求日までです。その日から上記の料金が請求されます。",
        "ko": "체험은 다음 결제일까지이며, 당일부터 위 금액이 청구됩니다.",
        "de": "Die Testphase läuft bis zum nächsten Abbuchungstag. Ab dann gilt der Betrag oben.",
        "fr": "L’essai dure jusqu’à la prochaine date de prélèvement, qui démarre le tarif ci-dessus.",
        "es": "La prueba dura hasta la próxima fecha de cobro; ese día empieza el importe de arriba.",
        "it": "La prova dura fino alla prossima data di addebito; da quel giorno vale l’importo sopra.",
        "pt-BR": "O teste vai até a próxima data de cobrança; nesse dia começa o valor acima.",
    },
    "银行转账": {
        "en": "Bank transfer", "zh-Hant": "銀行轉帳", "ja": "銀行振込",
        "ko": "계좌이체", "de": "Überweisung", "fr": "Virement bancaire",
        "es": "Transferencia bancaria", "it": "Bonifico", "pt-BR": "Transferência bancária",
    },
    "默认": {
        "en": "Default", "zh-Hant": "預設", "ja": "デフォルト",
        "ko": "기본", "de": "Standard", "fr": "Par défaut",
        "es": "Predeterminado", "it": "Predefinito", "pt-BR": "Padrão",
    },
    "默认货币": {
        "en": "Default currency", "zh-Hant": "預設貨幣", "ja": "デフォルト通貨",
        "ko": "기본 통화", "de": "Standardwährung", "fr": "Devise par défaut",
        "es": "Moneda predeterminada", "it": "Valuta predefinita", "pt-BR": "Moeda padrão",
    },
    "约 %@": {
        "en": "≈ %@", "zh-Hant": "約 %@", "ja": "約 %@",
        "ko": "약 %@", "de": "ca. %@", "fr": "env. %@",
        "es": "aprox. %@", "it": "circa %@", "pt-BR": "cerca de %@",
    },
    "隐私政策（网页）": {
        "en": "Privacy Policy (web)", "zh-Hant": "隱私政策（網頁）", "ja": "プライバシーポリシー（Web）",
        "ko": "개인정보 처리방침(웹)", "de": "Datenschutz (Web)", "fr": "Politique de confidentialité (web)",
        "es": "Política de privacidad (web)", "it": "Informativa sulla privacy (web)", "pt-BR": "Política de privacidade (web)",
    },
    "用户协议（网页）": {
        "en": "Terms of Use (web)", "zh-Hant": "使用者條款（網頁）", "ja": "利用規約（Web）",
        "ko": "이용약관(웹)", "de": "Nutzungsbedingungen (Web)", "fr": "Conditions d’utilisation (web)",
        "es": "Términos de uso (web)", "it": "Termini di utilizzo (web)", "pt-BR": "Termos de uso (web)",
    },
    "本机，可选 iCloud 备份": {
        "en": "On this device; optional iCloud backup",
        "zh-Hant": "本機，可選 iCloud 備份",
        "ja": "このデバイス（任意で iCloud バックアップ）",
        "ko": "이 기기, iCloud 백업 선택 가능",
        "de": "Auf dem Gerät, optional iCloud-Backup",
        "fr": "Sur l’appareil, sauvegarde iCloud facultative",
        "es": "En el dispositivo, copia iCloud opcional",
        "it": "Sul dispositivo, backup iCloud opzionale",
        "pt-BR": "Neste dispositivo, com backup iCloud opcional",
    },
    "关注我们": {
        "en": "Follow us", "zh-Hant": "關注我們", "ja": "フォローする",
        "ko": "팔로우", "de": "Folge uns", "fr": "Nous suivre",
        "es": "Síguenos", "it": "Seguici", "pt-BR": "Siga-nos",
    },
    "法律": {
        "en": "Legal", "zh-Hant": "法律", "ja": "法務",
        "ko": "법률", "de": "Rechtliches", "fr": "Mentions légales",
        "es": "Legal", "it": "Note legali", "pt-BR": "Jurídico",
    },
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def fill_file(path: Path, upsert_translations: bool = False) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    added = 0
    strings = data.setdefault("strings", {})
    for key, entry in list(strings.items()):
        if entry is None:
            entry = {}
            strings[key] = entry
        locs = entry.setdefault("localizations", {})
        mapping = TRANSLATIONS.get(key)
        if mapping is None:
            # identical across locales for leftover empty brand-like keys
            if not locs:
                mapping = {lang: key for lang in LANGS}
            else:
                continue
        for lang in LANGS:
            current = ((locs.get(lang) or {}).get("stringUnit") or {}).get("value")
            if current:
                continue
            if lang not in mapping:
                continue
            locs[lang] = unit(mapping[lang])
            added += 1
        if "zh-Hans" not in locs and key:
            locs["zh-Hans"] = unit(key)
    if upsert_translations:
        for key, mapping in TRANSLATIONS.items():
            entry = strings.setdefault(key, {})
            if entry is None:
                entry = {}
                strings[key] = entry
            locs = entry.setdefault("localizations", {})
            if "extractionState" not in entry:
                entry["extractionState"] = "manual"
            locs.setdefault("zh-Hans", unit(key))
            for lang in LANGS:
                current = ((locs.get(lang) or {}).get("stringUnit") or {}).get("value")
                if current:
                    continue
                locs[lang] = unit(mapping[lang])
                added += 1
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return added


def fill_infoplist(path: Path, bundle_name: str, copyright_value: str | None = None) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    strings = data.setdefault("strings", {})
    name_entry = strings.setdefault("CFBundleName", {"comment": "Bundle name", "localizations": {}})
    locs = name_entry.setdefault("localizations", {})
    for lang in ["zh-Hans", *LANGS]:
        locs[lang] = unit(bundle_name)
    name_entry["extractionState"] = "extracted_with_value"
    if copyright_value is not None:
        copy_entry = strings.setdefault(
            "NSHumanReadableCopyright",
            {"comment": "Copyright (human-readable)", "localizations": {}},
        )
        copy_locs = copy_entry.setdefault("localizations", {})
        for lang in ["zh-Hans", *LANGS]:
            copy_locs[lang] = unit(copyright_value)
        copy_entry["extractionState"] = "extracted_with_value"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    app = ROOT / "Renewity" / "Localizable.xcstrings"
    widget = ROOT / "RenewityWidget" / "Localizable.xcstrings"
    print("app added", fill_file(app, upsert_translations=True))
    print("widget added", fill_file(widget))
    fill_infoplist(ROOT / "Renewity" / "InfoPlist.xcstrings", "Renewity")
    fill_infoplist(
        ROOT / "RenewityWidget" / "InfoPlist.xcstrings",
        "RenewityWidget",
        copyright_value="© Renewity",
    )


if __name__ == "__main__":
    main()
