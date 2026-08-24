#!/usr/bin/env python3
"""Fill missing Localizable / InfoPlist string catalog translations."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGS = ["en", "zh-Hant", "ja", "ko", "de", "fr", "es", "it", "pt-BR"]


def same(value: str) -> dict[str, str]:
    return {lang: value for lang in LANGS}


# source (zh-Hans) -> translations
TRANSLATIONS: dict[str, dict[str, str]] = {
    "app.versionWithBuild": {
        "en": "%@ (%@)", "zh-Hant": "%@（%@）", "ja": "%@（%@）", "ko": "%@(%@)",
        "de": "%@ (%@)", "fr": "%@ (%@)", "es": "%@ (%@)", "it": "%@ (%@)", "pt-BR": "%@ (%@)",
    },
    "calendar.dayWithNames": {
        "en": "%@, %@", "zh-Hant": "%@，%@", "ja": "%@、%@", "ko": "%@, %@",
        "de": "%@, %@", "fr": "%@, %@", "es": "%@, %@", "it": "%@, %@", "pt-BR": "%@, %@",
    },
    "paywall.price.perYear": {
        "en": "/yr", "zh-Hant": "/年", "ja": "/年", "ko": "/년", "de": "/Jahr",
        "fr": "/an", "es": "/año", "it": "/anno", "pt-BR": "/ano",
    },
    "paywall.price.perMonth": {
        "en": "/mo", "zh-Hant": "/月", "ja": "/月", "ko": "/월", "de": "/Monat",
        "fr": "/mois", "es": "/mes", "it": "/mese", "pt-BR": "/mês",
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
    "%@ · %lld 笔": {
        "en": "%@ · %lld", "zh-Hant": "%@ · %lld 筆", "ja": "%@ · %lld件",
        "ko": "%@ · %lld건", "de": "%@ · %lld", "fr": "%@ · %lld",
        "es": "%@ · %lld", "it": "%@ · %lld", "pt-BR": "%@ · %lld",
    },
    "%lld 笔": {
        "en": "%lld", "zh-Hant": "%lld 筆", "ja": "%lld件",
        "ko": "%lld건", "de": "%lld", "fr": "%lld",
        "es": "%lld", "it": "%lld", "pt-BR": "%lld",
    },
    "American Express": same("American Express"),
    "Apple Pay": same("Apple Pay"),
    "Google Pay": same("Google Pay"),
    "Mastercard": same("Mastercard"),
    "PayPal": same("PayPal"),
    "Pro": same("Pro"),
    "Visa": same("Visa"),
    "一次性购买": {
        "en": "One-time purchase", "zh-Hant": "一次性購買", "ja": "買い切り",
        "ko": "일회성 구입", "de": "Einmalkauf", "fr": "Achat unique",
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
    "货币": {
        "en": "Currency", "zh-Hant": "貨幣", "ja": "通貨",
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
    "总览和分类合计会按参考汇率换算到此货币，仅供参考，不会改写各笔订阅记下的金额。": {
        "en": "Overview and category totals convert into this currency using reference rates. Amounts you recorded for each subscription stay unchanged.",
        "zh-Hant": "總覽和分類合計會按參考匯率換算到此貨幣，僅供參考，不會改寫各筆訂閱記下的金額。",
        "ja": "概要とカテゴリ合計はこの参考レートで換算されます。各サブスクに記録した金額は変わりません。",
        "ko": "개요와 분류 합계는 참고 환율로 이 통화로 환산됩니다. 각 구독에 기록한 금액은 바뀌지 않습니다.",
        "de": "Übersicht und Kategorie-Summen rechnen mit Referenzkursen in diese Währung um. Die erfassten Beträge bleiben unverändert.",
        "fr": "L’aperçu et les totaux par catégorie sont convertis avec des taux de référence. Les montants saisis ne changent pas.",
        "es": "El resumen y los totales por categoría se convierten con tipos de referencia. Los importes guardados no cambian.",
        "it": "Panoramica e totali per categoria sono convertiti con tassi di riferimento. Gli importi registrati non cambiano.",
        "pt-BR": "Visão geral e totais por categoria são convertidos com taxas de referência. Os valores registrados não mudam.",
    },
    "总览和分类合计按默认货币换算。轻点概览卡片可切换到第二种货币。选择货币需要 Renewity Pro。": {
        "en": "Overview and category totals convert using the default currency. Tap the overview card to switch to the second currency. Choosing a currency requires Renewity Pro.",
        "zh-Hant": "總覽和分類合計按預設貨幣換算。輕點概覽卡片可切換到第二種貨幣。選擇貨幣需要 Renewity Pro。",
        "ja": "概要とカテゴリ合計はデフォルト通貨で換算されます。概要カードをタップすると第二通貨に切り替えられます。通貨の選択には Renewity Pro が必要です。",
        "ko": "개요와 분류 합계는 기본 통화로 환산됩니다. 개요 카드를 눌러 두 번째 통화로 바꿀 수 있습니다. 통화 선택에는 Renewity Pro가 필요합니다.",
        "de": "Übersicht und Kategorie-Summen rechnen in die Standardwährung um. Tippe auf die Übersicht, um zur zweiten Währung zu wechseln. Währungswahl erfordert Renewity Pro.",
        "fr": "L’aperçu et les totaux par catégorie sont convertis dans la devise par défaut. Touchez la carte d’aperçu pour passer à la seconde devise. Choisir une devise nécessite Renewity Pro.",
        "es": "El resumen y los totales por categoría se convierten a la moneda predeterminada. Toca la tarjeta de resumen para cambiar a la segunda moneda. Elegir moneda requiere Renewity Pro.",
        "it": "Panoramica e totali per categoria sono convertiti nella valuta predefinita. Tocca la scheda panoramica per passare alla seconda valuta. Scegliere una valuta richiede Renewity Pro.",
        "pt-BR": "Visão geral e totais por categoria são convertidos na moeda padrão. Toque no cartão de visão geral para mudar para a segunda moeda. Escolher uma moeda exige Renewity Pro.",
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
    "自动续订": {
        "en": "Auto-renew", "zh-Hant": "自動續訂", "ja": "自動更新",
        "ko": "자동 갱신", "de": "Auto-Verlängerung", "fr": "Renouvellement auto",
        "es": "Renovación automática", "it": "Rinnovo automatico", "pt-BR": "Renovação automática",
    },
    "一次性": {
        "en": "One-time", "zh-Hant": "一次性", "ja": "都度払い",
        "ko": "일회성", "de": "Einmalig", "fr": "Unique",
        "es": "Único", "it": "Una tantum", "pt-BR": "Único",
    },
    "下次付款": {
        "en": "Next payment", "zh-Hant": "下次付款", "ja": "次回の支払い",
        "ko": "다음 결제", "de": "Nächste Zahlung", "fr": "Prochain paiement",
        "es": "Próximo pago", "it": "Prossimo pagamento", "pt-BR": "Próximo pagamento",
    },
    "上次付款": {
        "en": "Last payment", "zh-Hant": "上次付款", "ja": "前回の支払い",
        "ko": "최근 결제", "de": "Letzte Zahlung", "fr": "Dernier paiement",
        "es": "Último pago", "it": "Ultimo pagamento", "pt-BR": "Último pagamento",
    },
    "付款日期": {
        "en": "Payment date", "zh-Hant": "付款日期", "ja": "支払日",
        "ko": "결제일", "de": "Zahlungsdatum", "fr": "Date de paiement",
        "es": "Fecha de pago", "it": "Data di pagamento", "pt-BR": "Data de pagamento",
    },
    "付款货币": {
        "en": "Payment currency", "zh-Hant": "付款貨幣", "ja": "支払い通貨",
        "ko": "결제 통화", "de": "Zahlungswährung", "fr": "Devise de paiement",
        "es": "Moneda de pago", "it": "Valuta di pagamento", "pt-BR": "Moeda de pagamento",
    },
    "续订提醒": {
        "en": "Renewal reminders", "zh-Hant": "續訂提醒", "ja": "更新リマインダー",
        "ko": "갱신 알림", "de": "Verlängerungserinnerungen", "fr": "Rappels de renouvellement",
        "es": "Avisos de renovación", "it": "Promemoria rinnovo", "pt-BR": "Lembretes de renovação",
    },
    "付款提醒": {
        "en": "Payment reminders", "zh-Hant": "付款提醒", "ja": "支払いリマインダー",
        "ko": "결제 알림", "de": "Zahlungserinnerungen", "fr": "Rappels de paiement",
        "es": "Avisos de pago", "it": "Promemoria pagamento", "pt-BR": "Lembretes de pagamento",
    },
    "续订": {
        "en": "Renewal", "zh-Hant": "續訂", "ja": "更新",
        "ko": "갱신", "de": "Verlängerung", "fr": "Renouvellement",
        "es": "Renovación", "it": "Rinnovo", "pt-BR": "Renovação",
    },
    "付款": {
        "en": "Payment", "zh-Hant": "付款", "ja": "支払い",
        "ko": "결제", "de": "Zahlung", "fr": "Paiement",
        "es": "Pago", "it": "Pagamento", "pt-BR": "Pagamento",
    },
    "每次付款": {
        "en": "Each payment", "zh-Hant": "每次付款", "ja": "1回の支払い",
        "ko": "결제마다", "de": "Jede Zahlung", "fr": "Chaque paiement",
        "es": "Cada pago", "it": "Ogni pagamento", "pt-BR": "Cada pagamento",
    },
    "两周内到期": {
        "en": "Due in 2 weeks", "zh-Hant": "兩週內到期", "ja": "2週間以内",
        "ko": "2주 내 만료", "de": "In 2 Wochen fällig", "fr": "Dans 2 semaines",
        "es": "En 2 semanas", "it": "Entro 2 settimane", "pt-BR": "Em 2 semanas",
    },
    "即将续订": {
        "en": "Upcoming renewals", "zh-Hant": "即將續訂", "ja": "更新が近い",
        "ko": "곧 갱신", "de": "Anstehende Verlängerungen", "fr": "Renouvellements à venir",
        "es": "Próximas renovaciones", "it": "Rinnovi in arrivo", "pt-BR": "Renovações em breve",
    },
    "未来两周没有付款": {
        "en": "No payments in the next two weeks", "zh-Hant": "未來兩週沒有付款", "ja": "今後2週間の支払いはありません",
        "ko": "향후 2주간 결제 없음", "de": "Keine Zahlungen in den nächsten zwei Wochen", "fr": "Aucun paiement dans les deux prochaines semaines",
        "es": "No hay pagos en las próximas dos semanas", "it": "Nessun pagamento nelle prossime due settimane", "pt-BR": "Nenhum pagamento nas próximas duas semanas",
    },
    "年均": {
        "en": "Annualized", "zh-Hant": "年均", "ja": "年換算",
        "ko": "연환산", "de": "Jahreswert", "fr": "Annualisé",
        "es": "Anualizado", "it": "Annualizzato", "pt-BR": "Anualizado",
    },
    "订阅即将续订": {
        "en": "Renewal coming up", "zh-Hant": "訂閱即將續訂", "ja": "まもなく更新されます",
        "ko": "곧 갱신됩니다", "de": "Verlängerung steht bevor", "fr": "Renouvellement imminent",
        "es": "Renovación próxima", "it": "Rinnovo imminente", "pt-BR": "Renovação em breve",
    },
    "订阅即将付款": {
        "en": "Payment coming up", "zh-Hant": "訂閱即將付款", "ja": "まもなく支払いがあります",
        "ko": "곧 결제됩니다", "de": "Zahlung steht bevor", "fr": "Paiement imminent",
        "es": "Pago próximo", "it": "Pagamento imminente", "pt-BR": "Pagamento em breve",
    },
    "今天续订": {
        "en": "Renews today", "zh-Hant": "今天續訂", "ja": "今日更新",
        "ko": "오늘 갱신", "de": "Verlängert sich heute", "fr": "Renouvelle aujourd’hui",
        "es": "Se renueva hoy", "it": "Si rinnova oggi", "pt-BR": "Renova hoje",
    },
    "明天续订": {
        "en": "Renews tomorrow", "zh-Hant": "明天續訂", "ja": "明日更新",
        "ko": "내일 갱신", "de": "Verlängert sich morgen", "fr": "Renouvelle demain",
        "es": "Se renueva mañana", "it": "Si rinnova domani", "pt-BR": "Renova amanhã",
    },
    "%lld 天后续订": {
        "en": "Renews in %lld days", "zh-Hant": "%lld 天後續訂", "ja": "%lld 日後に更新",
        "ko": "%lld일 후 갱신", "de": "Verlängerung in %lld Tagen", "fr": "Renouvelle dans %lld j",
        "es": "Se renueva en %lld días", "it": "Si rinnova tra %lld giorni", "pt-BR": "Renova em %lld dias",
    },
    "今天付款": {
        "en": "Pays today", "zh-Hant": "今天付款", "ja": "今日支払い",
        "ko": "오늘 결제", "de": "Zahlung heute", "fr": "Paiement aujourd’hui",
        "es": "Pago hoy", "it": "Pagamento oggi", "pt-BR": "Pagamento hoje",
    },
    "明天付款": {
        "en": "Pays tomorrow", "zh-Hant": "明天付款", "ja": "明日支払い",
        "ko": "내일 결제", "de": "Zahlung morgen", "fr": "Paiement demain",
        "es": "Pago mañana", "it": "Pagamento domani", "pt-BR": "Pagamento amanhã",
    },
    "%lld 天后付款": {
        "en": "Pays in %lld days", "zh-Hant": "%lld 天後付款", "ja": "%lld 日後に支払い",
        "ko": "%lld일 후 결제", "de": "Zahlung in %lld Tagen", "fr": "Paiement dans %lld j",
        "es": "Pago en %lld días", "it": "Pagamento tra %lld giorni", "pt-BR": "Pagamento em %lld dias",
    },
    "「%@」将于明天续订 %@": {
        "en": "“%@” renews tomorrow for %@",
        "zh-Hant": "「%@」將於明天續訂 %@",
        "ja": "「%@」は明日 %@ で更新されます",
        "ko": "「%@」이(가) 내일 %@에 갱신됩니다",
        "de": "„%@“ verlängert sich morgen um %@",
        "fr": "« %@ » se renouvelle demain pour %@",
        "es": "«%@» se renueva mañana por %@",
        "it": "“%@” si rinnova domani per %@",
        "pt-BR": "“%@” renova amanhã por %@",
    },
    "「%@」将于 %lld 天后续订 %@": {
        "en": "“%@” renews in %lld days for %@",
        "zh-Hant": "「%@」將於 %lld 天後續訂 %@",
        "ja": "「%@」は %lld 日後に %@ で更新されます",
        "ko": "「%@」이(가) %lld일 후 %@에 갱신됩니다",
        "de": "„%@“ verlängert sich in %lld Tagen um %@",
        "fr": "« %@ » se renouvelle dans %lld jours pour %@",
        "es": "«%@» se renueva en %lld días por %@",
        "it": "“%@” si rinnova tra %lld giorni per %@",
        "pt-BR": "“%@” renova em %lld dias por %@",
    },
    "「%@」将于明天付款 %@": {
        "en": "“%@” will be billed tomorrow for %@",
        "zh-Hant": "「%@」將於明天付款 %@",
        "ja": "「%@」は明日 %@ が支払われます",
        "ko": "「%@」이(가) 내일 %@에 결제됩니다",
        "de": "„%@“ wird morgen um %@ fällig",
        "fr": "« %@ » sera payé demain pour %@",
        "es": "«%@» se pagará mañana por %@",
        "it": "“%@” sarà pagato domani per %@",
        "pt-BR": "“%@” será pago amanhã por %@",
    },
    "「%@」将于 %lld 天后付款 %@": {
        "en": "“%@” will be billed in %lld days for %@",
        "zh-Hant": "「%@」將於 %lld 天後付款 %@",
        "ja": "「%@」は %lld 日後に %@ が支払われます",
        "ko": "「%@」이(가) %lld일 후 %@에 결제됩니다",
        "de": "„%@“ wird in %lld Tagen um %@ fällig",
        "fr": "« %@ » sera payé dans %lld jours pour %@",
        "es": "«%@» se pagará en %lld días por %@",
        "it": "“%@” sarà pagato tra %lld giorni per %@",
        "pt-BR": "“%@” será pago em %lld dias por %@",
    },
    "「%@」将于明天结束试用，随后付款 %@": {
        "en": "“%@” trial ends tomorrow, then %@ will be billed",
        "zh-Hant": "「%@」將於明天結束試用，隨後付款 %@",
        "ja": "「%@」の無料期間は明日終了し、その後 %@ が支払われます",
        "ko": "「%@」 체험이 내일 끝나고 %@이(가) 결제됩니다",
        "de": "Die Testphase von „%@“ endet morgen, danach wird %@ fällig",
        "fr": "L’essai de « %@ » se termine demain, puis %@ sera prélevé",
        "es": "La prueba de «%@» termina mañana y luego se pagará %@",
        "it": "La prova di “%@” termina domani, poi verrà addebitato %@",
        "pt-BR": "O teste de “%@” termina amanhã e então %@ será cobrado",
    },
    "「%@」将于 %lld 天后结束试用，随后付款 %@": {
        "en": "“%@” trial ends in %lld days, then %@ will be billed",
        "zh-Hant": "「%@」將於 %lld 天後結束試用，隨後付款 %@",
        "ja": "「%@」の無料期間は %lld 日後に終了し、その後 %@ が支払われます",
        "ko": "「%@」 체험이 %lld일 후 끝나고 %@이(가) 결제됩니다",
        "de": "Die Testphase von „%@“ endet in %lld Tagen, danach wird %@ fällig",
        "fr": "L’essai de « %@ » se termine dans %lld jours, puis %@ sera prélevé",
        "es": "La prueba de «%@» termina en %lld días y luego se pagará %@",
        "it": "La prova di “%@” termina tra %lld giorni, poi verrà addebitato %@",
        "pt-BR": "O teste de “%@” termina em %lld dias e então %@ será cobrado",
    },
    "试用持续到下次付款日，当天开始按上面的费用付款。": {
        "en": "The trial lasts until the next payment date, then billing starts at the amount above.",
        "zh-Hant": "試用持續到下次付款日，當天開始按上面的費用付款。",
        "ja": "無料期間は次回支払日まで続き、当日から上記の料金で支払われます。",
        "ko": "체험은 다음 결제일까지이며, 그날부터 위의 금액으로 결제됩니다.",
        "de": "Die Testphase läuft bis zum nächsten Zahlungsdatum; ab dann gilt der Betrag oben.",
        "fr": "L’essai dure jusqu’à la prochaine date de paiement, puis le montant ci-dessus s’applique.",
        "es": "La prueba dura hasta la próxima fecha de pago; ese día empieza a cobrarse el importe de arriba.",
        "it": "La prova dura fino alla prossima data di pagamento; da quel giorno vale l’importo sopra.",
        "pt-BR": "O teste vai até a próxima data de pagamento; nesse dia começa a valer o valor acima.",
    },
    "选择付款日期或到期日": {
        "en": "Choose payment date or expiry date",
        "zh-Hant": "選擇付款日期或到期日",
        "ja": "支払日または有効期限を選択",
        "ko": "결제일 또는 만료일 선택",
        "de": "Zahlungs- oder Ablaufdatum wählen",
        "fr": "Choisir la date de paiement ou d’expiration",
        "es": "Elige fecha de pago o de caducidad",
        "it": "Scegli data di pagamento o di scadenza",
        "pt-BR": "Escolha a data de pagamento ou de validade",
    },
    "选择下次付款或上次付款": {
        "en": "Choose next payment or last payment",
        "zh-Hant": "選擇下次付款或上次付款",
        "ja": "次回の支払いまたは前回の支払いを選択",
        "ko": "다음 결제 또는 최근 결제 선택",
        "de": "Nächste oder letzte Zahlung wählen",
        "fr": "Choisir le prochain ou le dernier paiement",
        "es": "Elige el próximo pago o el último",
        "it": "Scegli il prossimo o l’ultimo pagamento",
        "pt-BR": "Escolha o próximo ou o último pagamento",
    },
    "改默认货币、付款货币，并把合计换算到其他货币": {
        "en": "Change display and payment currencies, and convert totals",
        "zh-Hant": "改預設貨幣、付款貨幣，並把合計換算到其他貨幣",
        "ja": "表示通貨・支払い通貨を変更し、合計を換算",
        "ko": "기본 통화와 결제 통화를 바꾸고 합계를 환산",
        "de": "Anzeige- und Zahlungswährung ändern und Summen umrechnen",
        "fr": "Changer les devises d’affichage et de paiement, et convertir les totaux",
        "es": "Cambiar moneda de visualización y de pago, y convertir totales",
        "it": "Cambia valuta di visualizzazione e di pagamento e converti i totali",
        "pt-BR": "Alterar moedas de exibição e pagamento e converter totais",
    },
    "一次性订阅不计入这些指标。日历上仍会显示圆点，但不会加入金额。": {
        "en": "One-time subscriptions are not included in these figures. They still appear as dots on the calendar, but are not added to the totals.",
        "zh-Hant": "一次性訂閱不計入這些指標。日曆上仍會顯示圓點，但不會加入金額。",
        "ja": "都度払いのサブスクはこれらの数値に含まれません。カレンダーには点が表示されますが、合計には加算されません。",
        "ko": "일회성 구독은 이 수치에 포함되지 않습니다. 캘린더에는 점이 표시되지만 합계에는 더하지 않습니다.",
        "de": "Einmalige Abos fließen nicht in diese Kennzahlen ein. Im Kalender erscheinen sie weiterhin als Punkte, werden aber nicht zu den Beträgen addiert.",
        "fr": "Les abonnements uniques ne sont pas inclus dans ces indicateurs. Ils apparaissent encore en points sur le calendrier, mais ne s’ajoutent pas aux montants.",
        "es": "Las suscripciones únicas no entran en estas cifras. Siguen apareciendo como puntos en el calendario, pero no se suman a los importes.",
        "it": "Gli abbonamenti una tantum non rientrano in questi valori. Restano visibili come punti nel calendario, ma non vengono sommati agli importi.",
        "pt-BR": "Assinaturas únicas não entram nestes indicadores. Elas ainda aparecem como pontos no calendário, mas não são somadas aos valores.",
    },
    "如果每笔自动续订的订阅都按今天的价格再付满一年，就是年均支出。各周期会先换成每月金额，再乘以 12。已暂停、试用中还没首次付款的不计入。": {
        "en": "Annualized spend if every auto-renewing subscription continues for a full year at today’s price. Each cycle is converted to a monthly amount, then multiplied by 12. Paused subscriptions and trials that have not started billing are excluded.",
        "zh-Hant": "如果每筆自動續訂的訂閱都按今天的價格再付滿一年，就是年均支出。各週期會先換成每月金額，再乘以 12。已暫停、試用中還沒首次付款的不計入。",
        "ja": "自動更新の各サブスクが今日の価格のまま1年間続くと仮定した年換算支出です。各周期を月額に換算して12倍します。一時停止中と、まだ初回支払いがない無料期間は含みません。",
        "ko": "자동 갱신 구독이 오늘 가격으로 1년 동안 유지된다고 가정한 연환산 지출입니다. 각 주기를 월 금액으로 바꾼 뒤 12를 곱합니다. 일시중지와 아직 첫 결제가 없는 체험은 포함하지 않습니다.",
        "de": "Jahresausgaben, wenn jedes Auto-Abo ein Jahr lang zum heutigen Preis weiterläuft. Jeder Zyklus wird in einen Monatsbetrag umgerechnet und mit 12 multipliziert. Pausierte Abos und Tests ohne erste Zahlung zählen nicht.",
        "fr": "Dépense annualisée si chaque abonnement à renouvellement automatique continue un an au prix d’aujourd’hui. Chaque cycle est converti en montant mensuel, puis multiplié par 12. Les abonnements en pause et les essais sans premier paiement sont exclus.",
        "es": "Gasto anualizado si cada suscripción de renovación automática continúa un año al precio de hoy. Cada ciclo se convierte a un importe mensual y se multiplica por 12. No se incluyen las pausadas ni las pruebas sin el primer pago.",
        "it": "Spesa annualizzata se ogni abbonamento a rinnovo automatico continua per un anno al prezzo odierno. Ogni ciclo è convertito in importo mensile e moltiplicato per 12. Sono esclusi quelli in pausa e le prove senza il primo pagamento.",
        "pt-BR": "Gasto anualizado se cada assinatura com renovação automática continuar por um ano no preço de hoje. Cada ciclo vira um valor mensal e é multiplicado por 12. Pausadas e testes sem o primeiro pagamento ficam de fora.",
    },
    "从今天起到今年 12 月 31 日，这些自动续订的订阅实际还会付款几次，把这几次的金额加起来。年内已经付过、不会再付的不计入。": {
        "en": "From today through December 31, add up each remaining payment for these auto-renewing subscriptions. Payments that already happened this year and will not occur again this year are excluded.",
        "zh-Hant": "從今天起到今年 12 月 31 日，這些自動續訂的訂閱實際還會付款幾次，把這幾次的金額加起來。年內已經付過、不會再付的不計入。",
        "ja": "今日から今年の12月31日までに、これらの自動更新が実際に発生する回数の金額を合計します。年内にすでに支払い済みで、今年中に再支払いされない分は含みません。",
        "ko": "오늘부터 올해 12월 31일까지 이 자동 갱신 구독이 실제로 더 결제되는 횟수의 금액을 합산합니다. 올해 이미 결제되어 더 이상 결제되지 않는 건은 포함하지 않습니다.",
        "de": "Von heute bis zum 31. Dezember werden die noch anstehenden Zahlungen dieser Auto-Abos addiert. Zahlungen, die in diesem Jahr bereits erfolgt sind und nicht erneut anfallen, zählen nicht.",
        "fr": "Du jour jusqu’au 31 décembre, additionnez les paiements encore prévus pour ces abonnements. Ceux déjà effectués cette année et qui ne se reproduiront pas cette année sont exclus.",
        "es": "Desde hoy hasta el 31 de diciembre se suman los pagos que aún ocurrirán de estas suscripciones. Los que ya ocurrieron este año y no volverán a ocurrir no se incluyen.",
        "it": "Da oggi al 31 dicembre si sommano i pagamenti ancora previsti per questi abbonamenti. Quelli già avvenuti quest’anno e che non si ripeteranno entro l’anno sono esclusi.",
        "pt-BR": "De hoje até 31 de dezembro, some cada pagamento restante dessas assinaturas. Pagamentos que já ocorreram neste ano e não vão se repetir ficam de fora.",
    },
    "当前查看的月份里，所有自动续订金额之和，包括本月已经过去的日子。": {
        "en": "The sum of all auto-renewal amounts in the month you are viewing, including days that have already passed.",
        "zh-Hant": "目前查看的月份裡，所有自動續訂金額之和，包括本月已經過去的日子。",
        "ja": "表示中の月における自動更新の合計です。すでに過ぎた日も含みます。",
        "ko": "현재 보는 달의 모든 자동 갱신 금액 합계이며, 이미 지난 날짜도 포함합니다.",
        "de": "Summe aller Auto-Verlängerungsbeträge im angezeigten Monat, einschließlich bereits vergangener Tage.",
        "fr": "Somme de tous les montants à renouvellement automatique du mois affiché, y compris les jours déjà passés.",
        "es": "Suma de todos los importes de renovación automática del mes que estás viendo, incluidos los días ya transcurridos.",
        "it": "Somma di tutti gli importi a rinnovo automatico del mese visualizzato, compresi i giorni già trascorsi.",
        "pt-BR": "Soma de todos os valores de renovação automática do mês exibido, incluindo os dias que já passaram.",
    },
    "当前查看的月份里，从今天（含今天）到月底还会发生的自动续订金额之和。查看过去的月份时为 0；查看未来的月份时与总计相同。": {
        "en": "Auto-renewal amounts still due from today through the end of the month you are viewing. This is 0 for past months, and matches the total for future months.",
        "zh-Hant": "目前查看的月份裡，從今天（含今天）到月底還會發生的自動續訂金額之和。查看過去的月份時為 0；查看未來的月份時與總計相同。",
        "ja": "表示中の月のうち、今日以降（当日を含む）月末までに発生する自動更新の合計です。過去の月は0、未来の月は合計と同じです。",
        "ko": "현재 보는 달에서 오늘(오늘 포함)부터 말일까지 남은 자동 갱신 금액 합계입니다. 지난달은 0이고, 다음 달은 합계와 같습니다.",
        "de": "Noch anstehende Auto-Verlängerungsbeträge vom heutigen Tag bis Monatsende im angezeigten Monat. Für vergangene Monate 0, für zukünftige Monate identisch mit der Gesamtsumme.",
        "fr": "Montants à renouvellement automatique encore dus d’aujourd’hui (inclus) à la fin du mois affiché. Vaut 0 pour un mois passé, et égale le total pour un mois futur.",
        "es": "Importes de renovación automática que quedan desde hoy (incluido) hasta fin de mes en el mes que estás viendo. Es 0 en meses pasados y coincide con el total en meses futuros.",
        "it": "Importi a rinnovo automatico ancora in programma da oggi (incluso) a fine mese nel mese visualizzato. È 0 per i mesi passati e coincide con il totale per i mesi futuri.",
        "pt-BR": "Valores de renovação automática que ainda ocorrem de hoje (inclusive) até o fim do mês exibido. É 0 em meses passados e igual ao total em meses futuros.",
    },
    "按每个订阅的续订和试用设置发送本地通知。": {
        "en": "Sends local notifications based on each subscription’s renewal and trial settings.",
        "zh-Hant": "按每個訂閱的續訂和試用設定發送本機通知。",
        "ja": "各サブスクの更新と無料期間の設定に基づいてローカル通知を送ります。",
        "ko": "각 구독의 갱신 및 체험 설정에 따라 로컬 알림을 보냅니다.",
        "de": "Sendet lokale Mitteilungen gemäß den Verlängerungs- und Testeinstellungen jedes Abos.",
        "fr": "Envoie des notifications locales selon les réglages de renouvellement et d’essai de chaque abonnement.",
        "es": "Envía notificaciones locales según la renovación y la prueba de cada suscripción.",
        "it": "Invia notifiche locali in base a rinnovo e prova di ogni abbonamento.",
        "pt-BR": "Envia notificações locais conforme a renovação e o teste de cada assinatura.",
    },
    "订阅名称、金额和日期都保存在你的设备上。续订提醒使用系统本地通知，不会上传到服务器。购买通过 Apple 完成。": {
        "en": "Subscription names, amounts, and dates stay on your device. Renewal reminders use local system notifications and are not uploaded to a server. Purchases are completed through Apple.",
        "zh-Hant": "訂閱名稱、金額和日期都保存在你的裝置上。續訂提醒使用系統本機通知，不會上傳到伺服器。購買透過 Apple 完成。",
        "ja": "サブスク名、金額、日付はデバイスに保存されます。更新リマインダーはシステムのローカル通知を使い、サーバーには送信しません。購入は Apple 経由です。",
        "ko": "구독 이름, 금액, 날짜는 기기에 저장됩니다. 갱신 알림은 시스템 로컬 알림을 쓰며 서버로 올라가지 않습니다. 구매는 Apple을 통해 이루어집니다.",
        "de": "Namen, Beträge und Daten bleiben auf dem Gerät. Verlängerungserinnerungen nutzen lokale Systemmitteilungen und werden nicht auf einen Server geladen. Käufe laufen über Apple.",
        "fr": "Noms, montants et dates restent sur l’appareil. Les rappels de renouvellement utilisent les notifications locales et ne sont pas envoyés à un serveur. Les achats passent par Apple.",
        "es": "Nombres, importes y fechas se quedan en el dispositivo. Los avisos de renovación usan notificaciones locales del sistema y no se suben a un servidor. Las compras se hacen con Apple.",
        "it": "Nomi, importi e date restano sul dispositivo. I promemoria di rinnovo usano le notifiche locali di sistema e non vengono caricati su un server. Gli acquisti passano da Apple.",
        "pt-BR": "Nomes, valores e datas ficam no dispositivo. Lembretes de renovação usam notificações locais do sistema e não vão para um servidor. As compras são feitas pela Apple.",
    },
    "按分类统计月费和年均支出，马上知道哪些订阅最贵，哪些可以砍掉。": {
        "en": "See monthly and annualized spend by category, and spot which subscriptions cost the most.",
        "zh-Hant": "按分類統計月費和年均支出，馬上知道哪些訂閱最貴、哪些可以砍掉。",
        "ja": "カテゴリ別に月額と年換算支出を見て、高いサブスクをすぐに把握できます。",
        "ko": "분류별 월 요금과 연환산 지출을 보고 어떤 구독이 가장 비싼지 바로 알 수 있습니다.",
        "de": "Sieh Monats- und Jahresausgaben nach Kategorie und erkennst sofort die teuersten Abos.",
        "fr": "Voyez les dépenses mensuelles et annualisées par catégorie, et repérez les abonnements les plus chers.",
        "es": "Consulta el gasto mensual y anualizado por categoría y detecta qué suscripciones son más caras.",
        "it": "Vedi spesa mensile e annualizzata per categoria e scopri subito quali abbonamenti costano di più.",
        "pt-BR": "Veja o gasto mensal e anualizado por categoria e descubra quais assinaturas saem mais caras.",
    },
    "续订前提醒你": {
        "en": "Get reminded before renewal",
        "zh-Hant": "續訂前提醒你",
        "ja": "更新前に知らせます",
        "ko": "갱신 전에 알려 드립니다",
        "de": "Vor der Verlängerung erinnert",
        "fr": "Un rappel avant le renouvellement",
        "es": "Aviso antes de renovar",
        "it": "Un promemoria prima del rinnovo",
        "pt-BR": "Um lembrete antes da renovação",
    },
    "在付款前一天收到通知，避免忘了取消，也不用再翻邮件找账单。": {
        "en": "Get a notification the day before payment so you can cancel in time—no need to hunt through email for the bill.",
        "zh-Hant": "在付款前一天收到通知，避免忘了取消，也不用再翻郵件找帳單。",
        "ja": "支払いの前日に通知するので、キャンセルし忘れを防げます。メールから請求を探す必要もありません。",
        "ko": "결제 하루 전에 알림을 받아 해지를 잊지 않고, 이메일에서 청구서를 찾을 필요도 없습니다.",
        "de": "Einen Tag vor der Zahlung kommt eine Mitteilung, damit du rechtzeitig kündigen kannst – ohne in E-Mails nach der Rechnung zu suchen.",
        "fr": "Une notification la veille du paiement pour ne pas oublier d’annuler, sans fouiller vos e-mails.",
        "es": "Recibe un aviso el día antes del pago para no olvidarte de cancelar, sin rebuscar el recibo en el correo.",
        "it": "Una notifica il giorno prima del pagamento così non dimentichi di disdire, senza cercare la ricevuta nelle email.",
        "pt-BR": "Receba um aviso no dia anterior ao pagamento para não esquecer de cancelar, sem vasculhar o e-mail atrás da fatura.",
    },
    "查看未来两周内即将付款的订阅。": {
        "en": "See subscriptions with payments due in the next two weeks.",
        "zh-Hant": "查看未來兩週內即將付款的訂閱。",
        "ja": "今後2週間以内に支払いがあるサブスクを表示します。",
        "ko": "향후 2주 안에 결제가 있는 구독을 봅니다.",
        "de": "Zeigt Abos mit Zahlungen in den nächsten zwei Wochen.",
        "fr": "Affiche les abonnements à payer dans les deux prochaines semaines.",
        "es": "Muestra las suscripciones con pagos en las próximas dos semanas.",
        "it": "Mostra gli abbonamenti con pagamenti nelle prossime due settimane.",
        "pt-BR": "Mostra assinaturas com pagamento nas próximas duas semanas.",
    },
    "查看本月订阅总支出和年均支出。": {
        "en": "See this month’s subscription spend and annualized spend.",
        "zh-Hant": "查看本月訂閱總支出和年均支出。",
        "ja": "今月のサブスク支出と年換算支出を表示します。",
        "ko": "이번 달 구독 지출과 연환산 지출을 봅니다.",
        "de": "Zeigt die Abo-Ausgaben dieses Monats und den Jahreswert.",
        "fr": "Affiche les dépenses d’abonnement du mois et la dépense annualisée.",
        "es": "Muestra el gasto en suscripciones de este mes y el gasto anualizado.",
        "it": "Mostra la spesa abbonamenti del mese e quella annualizzata.",
        "pt-BR": "Mostra o gasto com assinaturas deste mês e o gasto anualizado.",
    },
    "已结束": {
        "en": "Ended", "zh-Hant": "已結束", "ja": "終了",
        "ko": "종료됨", "de": "Beendet", "fr": "Terminé",
        "es": "Finalizado", "it": "Concluso", "pt-BR": "Encerrado",
    },
    "已付款": {
        "en": "Paid", "zh-Hant": "已付款", "ja": "支払い済み",
        "ko": "결제 완료", "de": "Bezahlt", "fr": "Payé",
        "es": "Pagado", "it": "Pagato", "pt-BR": "Pago",
    },
    "本年剩余支出": {
        "en": "Remaining this year", "zh-Hant": "本年剩餘支出", "ja": "年内の残り支出",
        "ko": "올해 남은 지출", "de": "Restausgaben in diesem Jahr", "fr": "Reste cette année",
        "es": "Resto de este año", "it": "Resto dell’anno", "pt-BR": "Restante neste ano",
    },
    "年均支出": {
        "en": "Annualized spend", "zh-Hant": "年均支出", "ja": "年換算支出",
        "ko": "연환산 지출", "de": "Jahresausgaben", "fr": "Dépense annualisée",
        "es": "Gasto anualizado", "it": "Spesa annualizzata", "pt-BR": "Gasto anualizado",
    },
    "关于数值": {
        "en": "About these numbers", "zh-Hant": "關於數值", "ja": "数値について",
        "ko": "수치 안내", "de": "Zu diesen Zahlen", "fr": "À propos des montants",
        "es": "Sobre estas cifras", "it": "Informazioni sui valori", "pt-BR": "Sobre estes valores",
    },
    "查看年均支出、本年剩余支出和日历金额的说明": {
        "en": "View explanations of annualized spend, remaining spend this year, and calendar totals",
        "zh-Hant": "查看年均支出、本年剩餘支出和日曆金額的說明",
        "ja": "年換算支出、年内残り支出、カレンダー金額の説明を表示します",
        "ko": "연환산 지출, 올해 남은 지출, 캘린더 금액 설명을 봅니다",
        "de": "Erläuterungen zu Jahresausgaben, Restausgaben und Kalenderbeträgen anzeigen",
        "fr": "Voir les explications de la dépense annualisée, du reste de l’année et des totaux du calendrier",
        "es": "Ver las explicaciones del gasto anualizado, el resto del año y los totales del calendario",
        "it": "Consulta le spiegazioni di spesa annualizzata, resto dell’anno e totali del calendario",
        "pt-BR": "Ver explicações do gasto anualizado, do restante neste ano e dos totais do calendário",
    },
    "切换年均支出和本年剩余支出的货币": {
        "en": "Switch the currency for annualized spend and remaining spend this year",
        "zh-Hant": "切換年均支出和本年剩餘支出的貨幣",
        "ja": "年換算支出と年内残り支出の通貨を切り替えます",
        "ko": "연환산 지출과 올해 남은 지출의 통화를 전환합니다",
        "de": "Währung für Jahresausgaben und Restausgaben wechseln",
        "fr": "Changer la devise de la dépense annualisée et du reste de l’année",
        "es": "Cambiar la moneda del gasto anualizado y del resto de este año",
        "it": "Cambia la valuta della spesa annualizzata e del resto dell’anno",
        "pt-BR": "Alternar a moeda do gasto anualizado e do restante neste ano",
    },
    "切换本年预计支出和本年剩余支出的货币": {
        "en": "Switch the currency for this year’s estimated and remaining spend",
        "zh-Hant": "切換本年預計支出和本年剩餘支出的貨幣",
        "ja": "今年の見込み支出と残りの通貨を切り替えます",
        "ko": "올해 예상 지출과 남은 지출의 통화를 전환합니다",
        "de": "Währung für geschätzte und restliche Jahresausgaben wechseln",
        "fr": "Changer la devise des dépenses estimées et restantes de l’année",
        "es": "Cambiar la moneda del gasto estimado y restante de este año",
        "it": "Cambia la valuta della spesa stimata e restante di quest’anno",
        "pt-BR": "Alternar a moeda do gasto estimado e restante deste ano",
    },
    "输入金额": {
        "en": "Enter amount", "zh-Hant": "輸入金額", "ja": "金額を入力",
        "ko": "금액 입력", "de": "Betrag eingeben", "fr": "Saisir le montant",
        "es": "Introduce el importe", "it": "Inserisci l’importo", "pt-BR": "Digite o valor",
    },
    "到期日": {
        "en": "Expiry date", "zh-Hant": "到期日", "ja": "有効期限",
        "ko": "만료일", "de": "Ablaufdatum", "fr": "Date d’expiration",
        "es": "Fecha de caducidad", "it": "Data di scadenza", "pt-BR": "Data de validade",
    },
    "已到期": {
        "en": "Expired", "zh-Hant": "已到期", "ja": "期限切れ",
        "ko": "만료됨", "de": "Abgelaufen", "fr": "Expiré",
        "es": "Caducado", "it": "Scaduto", "pt-BR": "Expirado",
    },
    "今天到期": {
        "en": "Expires today", "zh-Hant": "今天到期", "ja": "今日期限切れ",
        "ko": "오늘 만료", "de": "Läuft heute ab", "fr": "Expire aujourd’hui",
        "es": "Caduca hoy", "it": "Scade oggi", "pt-BR": "Expira hoje",
    },
    "明天到期": {
        "en": "Expires tomorrow", "zh-Hant": "明天到期", "ja": "明日期限切れ",
        "ko": "내일 만료", "de": "Läuft morgen ab", "fr": "Expire demain",
        "es": "Caduca mañana", "it": "Scade domani", "pt-BR": "Expira amanhã",
    },
    "%lld 天后到期": {
        "en": "Expires in %lld days", "zh-Hant": "%lld 天後到期", "ja": "%lld 日後に期限切れ",
        "ko": "%lld일 후 만료", "de": "Läuft in %lld Tagen ab", "fr": "Expire dans %lld j",
        "es": "Caduca en %lld días", "it": "Scade tra %lld giorni", "pt-BR": "Expira em %lld dias",
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
    "使用条款（网页）": {
        "en": "Terms of Use (web)", "zh-Hant": "使用條款（網頁）", "ja": "利用規約（Web）",
        "ko": "이용 약관(웹)", "de": "Nutzungsbedingungen (Web)", "fr": "Conditions d’utilisation (web)",
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
    "使用条款": {
        "en": "Terms of Use", "zh-Hant": "使用條款", "ja": "利用規約",
        "ko": "이용 약관", "de": "Nutzungsbedingungen", "fr": "Conditions d’utilisation",
        "es": "Términos de uso", "it": "Termini di utilizzo", "pt-BR": "Termos de uso",
    },
    "订阅类型": {
        "en": "Subscription type", "zh-Hant": "訂閱類型", "ja": "サブスクリプションの種類",
        "ko": "구독 유형", "de": "Abo-Typ", "fr": "Type d’abonnement",
        "es": "Tipo de suscripción", "it": "Tipo di abbonamento", "pt-BR": "Tipo de assinatura",
    },
    "App 锁定": {
        "en": "App Lock", "zh-Hant": "App 鎖定", "ja": "Appロック",
        "ko": "앱 잠금", "de": "App-Sperre", "fr": "Verrouillage de l’App",
        "es": "Bloqueo de la app", "it": "Blocco dell’app", "pt-BR": "Bloqueio do app",
    },
    "Renewity 已锁定": {
        "en": "Renewity is locked", "zh-Hant": "Renewity 已鎖定", "ja": "Renewity はロックされています",
        "ko": "Renewity가 잠겨 있습니다", "de": "Renewity ist gesperrt", "fr": "Renewity est verrouillé",
        "es": "Renewity está bloqueado", "it": "Renewity è bloccato", "pt-BR": "O Renewity está bloqueado",
    },
    "7 天免费试用": {
        "en": "7-day free trial", "zh-Hant": "7 天免費試用", "ja": "7日間の無料トライアル",
        "ko": "7일 무료 체험", "de": "7 Tage kostenlos testen", "fr": "Essai gratuit de 7 jours",
        "es": "Prueba gratis de 7 días", "it": "Prova gratuita di 7 giorni", "pt-BR": "Teste grátis de 7 dias",
    },
    "各货币月支出": {
        "en": "Monthly spend by currency", "zh-Hant": "各貨幣月支出", "ja": "通貨別の月額支出",
        "ko": "통화별 월 지출", "de": "Monatsausgaben nach Währung", "fr": "Dépenses mensuelles par devise",
        "es": "Gasto mensual por moneda", "it": "Spesa mensile per valuta", "pt-BR": "Gasto mensal por moeda",
    },
    "按每笔订阅的付款货币，把周期费用折成每月后直接相加，不做汇率换算。试用中还没首次付款的不计入。": {
        "en": "Adds each subscription’s monthly equivalent in its payment currency, without converting exchange rates. Trials that have not been billed yet are excluded.",
        "zh-Hant": "按每筆訂閱的付款貨幣，把週期費用折成每月後直接相加，不做匯率換算。試用中還沒首次付款的不計入。",
        "ja": "各サブスクの支払い通貨のまま月額換算して合計します。為替換算はしません。まだ初回支払いがない無料期間は含めません。",
        "ko": "각 구독의 결제 통화 기준 월 환산액을 더하며 환율은 적용하지 않습니다. 아직 첫 결제가 없는 체험은 제외됩니다.",
        "de": "Addiert die monatlichen Äquivalente in der Zahlungswährung jedes Abos ohne Umrechnung. Noch nicht abgerechnete Testphasen zählen nicht.",
        "fr": "Additionne l’équivalent mensuel dans la devise de paiement de chaque abonnement, sans conversion. Les essais non encore facturés sont exclus.",
        "es": "Suma el equivalente mensual en la moneda de pago de cada suscripción, sin convertir. Las pruebas aún no cobradas no entran.",
        "it": "Somma l’equivalente mensile nella valuta di pagamento di ogni abbonamento, senza conversione. Le prove non ancora addebitate sono escluse.",
        "pt-BR": "Soma o equivalente mensal na moeda de pagamento de cada assinatura, sem converter câmbio. Testes ainda não cobrados ficam de fora.",
    },
    "即将到来": {
        "en": "Upcoming", "zh-Hant": "即將到來", "ja": "近日",
        "ko": "예정", "de": "Demnächst", "fr": "À venir",
        "es": "Próximos", "it": "In arrivo", "pt-BR": "Em breve",
    },
    "总计": {
        "en": "Total", "zh-Hant": "總計", "ja": "合計",
        "ko": "합계", "de": "Summe", "fr": "Total",
        "es": "Total", "it": "Totale", "pt-BR": "Total",
    },
    "管理页面": {
        "en": "Manage page", "zh-Hant": "管理頁面", "ja": "管理ページ",
        "ko": "관리 페이지", "de": "Verwaltungsseite", "fr": "Page de gestion",
        "es": "Página de gestión", "it": "Pagina di gestione", "pt-BR": "Página de gerenciamento",
    },
    "第二种货币": {
        "en": "Second currency", "zh-Hant": "第二種貨幣", "ja": "第二の通貨",
        "ko": "두 번째 통화", "de": "Zweite Währung", "fr": "Seconde devise",
        "es": "Segunda moneda", "it": "Seconda valuta", "pt-BR": "Segunda moeda",
    },
    "选择第二种货币": {
        "en": "Choose a second currency", "zh-Hant": "選擇第二種貨幣", "ja": "第二の通貨を選択",
        "ko": "두 번째 통화 선택", "de": "Zweite Währung wählen", "fr": "Choisir une seconde devise",
        "es": "Elige una segunda moneda", "it": "Scegli una seconda valuta", "pt-BR": "Escolha uma segunda moeda",
    },
    "搜索已有订阅": {
        "en": "Search subscriptions", "zh-Hant": "搜尋現有訂閱", "ja": "登録済みのサブスクを検索",
        "ko": "기존 구독 검색", "de": "Abos durchsuchen", "fr": "Rechercher des abonnements",
        "es": "Buscar suscripciones", "it": "Cerca abbonamenti", "pt-BR": "Buscar assinaturas",
    },
    "日期类型": {
        "en": "Date type", "zh-Hant": "日期類型", "ja": "日付の種類",
        "ko": "날짜 유형", "de": "Datumstyp", "fr": "Type de date",
        "es": "Tipo de fecha", "it": "Tipo di data", "pt-BR": "Tipo de data",
    },
    "当前没有计入月支出的订阅": {
        "en": "No subscriptions currently count toward monthly spend",
        "zh-Hant": "目前沒有計入月支出的訂閱",
        "ja": "月額支出に含まれるサブスクはありません",
        "ko": "월 지출에 포함되는 구독이 없습니다",
        "de": "Derzeit zählen keine Abos zur Monatsausgabe",
        "fr": "Aucun abonnement n’entre actuellement dans les dépenses mensuelles",
        "es": "Ninguna suscripción cuenta ahora en el gasto mensual",
        "it": "Nessun abbonamento rientra al momento nella spesa mensile",
        "pt-BR": "Nenhuma assinatura entra no gasto mensal no momento",
    },
    "填写该服务的账号或订阅管理链接。点详情页的「管理订阅」会打开这个地址。": {
        "en": "Enter the account or subscription management URL for this service. Opening Manage Subscription on the detail page uses this address.",
        "zh-Hant": "填寫該服務的帳號或訂閱管理連結。點詳情頁的「管理訂閱」會打開這個地址。",
        "ja": "このサービスのアカウントまたは管理用 URL を入力します。詳細ページの「サブスクを管理」で開きます。",
        "ko": "이 서비스의 계정 또는 구독 관리 링크를 입력하세요. 상세 화면의 「구독 관리」에서 이 주소가 열립니다.",
        "de": "Gib Konto- oder Verwaltungs-URL des Dienstes ein. „Abo verwalten“ auf der Detailseite öffnet diese Adresse.",
        "fr": "Saisissez le compte ou l’URL de gestion. « Gérer l’abonnement » sur la fiche ouvre cette adresse.",
        "es": "Introduce la cuenta o el enlace de gestión. «Gestionar suscripción» en el detalle abre esta dirección.",
        "it": "Inserisci account o URL di gestione. «Gestisci abbonamento» nella scheda apre questo indirizzo.",
        "pt-BR": "Informe a conta ou o link de gerenciamento. «Gerenciar assinatura» nos detalhes abre este endereço.",
    },
    "本机，并可通过 iCloud 在设备间同步": {
        "en": "On this device, and can sync across devices with iCloud",
        "zh-Hant": "本機，並可透過 iCloud 在裝置間同步",
        "ja": "このデバイス（iCloud で他のデバイスと同期可能）",
        "ko": "이 기기, iCloud로 기기 간 동기화 가능",
        "de": "Auf dem Gerät, per iCloud zwischen Geräten synchronisierbar",
        "fr": "Sur l’appareil, synchronisable via iCloud",
        "es": "En el dispositivo; se puede sincronizar con iCloud",
        "it": "Sul dispositivo, sincronizzabile via iCloud",
        "pt-BR": "Neste dispositivo, com sincronização iCloud entre aparelhos",
    },
    "查看日历": {
        "en": "View calendar", "zh-Hant": "查看日曆", "ja": "カレンダーを表示",
        "ko": "캘린더 보기", "de": "Kalender anzeigen", "fr": "Voir le calendrier",
        "es": "Ver el calendario", "it": "Vedi il calendario", "pt-BR": "Ver calendário",
    },
    "删除分类": {
        "en": "Delete Category", "zh-Hant": "刪除分類", "ja": "カテゴリを削除",
        "ko": "분류 삭제", "de": "Kategorie löschen", "fr": "Supprimer la catégorie",
        "es": "Eliminar categoría", "it": "Elimina categoria", "pt-BR": "Apagar categoria",
    },
    "删除后，该分类下的订阅会改到剩余分类。": {
        "en": "Subscriptions in this category will move to another remaining category.",
        "zh-Hant": "刪除後，該分類下的訂閱會改到剩餘分類。",
        "ja": "削除後、このカテゴリのサブスクは残りのカテゴリに移ります。",
        "ko": "삭제하면 이 분류의 구독은 남은 분류로 옮겨집니다.",
        "de": "Abos dieser Kategorie werden einer verbleibenden Kategorie zugeordnet.",
        "fr": "Les abonnements de cette catégorie seront déplacés vers une catégorie restante.",
        "es": "Las suscripciones de esta categoría pasarán a otra categoría restante.",
        "it": "Gli abbonamenti di questa categoria passeranno a una categoria rimanente.",
        "pt-BR": "As assinaturas desta categoria irão para outra categoria restante.",
    },
    "删除后无法恢复。该分类下的订阅会改到剩余分类。": {
        "en": "This can’t be undone. Subscriptions in this category will move to another remaining category.",
        "zh-Hant": "刪除後無法恢復。該分類下的訂閱會改到剩餘分類。",
        "ja": "削除は取り消せません。このカテゴリのサブスクは残りのカテゴリに移ります。",
        "ko": "삭제하면 되돌릴 수 없습니다. 이 분류의 구독은 남은 분류로 옮겨집니다.",
        "de": "Das kann nicht rückgängig gemacht werden. Abos werden einer verbleibenden Kategorie zugeordnet.",
        "fr": "Action irréversible. Les abonnements seront déplacés vers une catégorie restante.",
        "es": "No se puede deshacer. Las suscripciones pasarán a otra categoría restante.",
        "it": "Operazione irreversibile. Gli abbonamenti passeranno a una categoria rimanente.",
        "pt-BR": "Isso não pode ser desfeito. As assinaturas irão para outra categoria restante.",
    },
    "轻点可编辑。点「编辑」后可拖动排序或删除。至少保留一个分类；删除后，该分类下的订阅会改到剩余分类。": {
        "en": "Tap to edit. After Edit, you can reorder or delete. Keep at least one category; subscriptions in a deleted category move to a remaining one.",
        "zh-Hant": "輕點可編輯。點「編輯」後可拖動排序或刪除。至少保留一個分類；刪除後，該分類下的訂閱會改到剩餘分類。",
        "ja": "タップで編集。「編集」後に並べ替えや削除ができます。カテゴリは1つ以上残してください。削除したカテゴリのサブスクは残りに移ります。",
        "ko": "눌러 편집합니다. 「편집」 후 순서를 바꾸거나 삭제할 수 있습니다. 분류는 하나 이상 남겨 두세요. 삭제된 분류의 구독은 남은 분류로 옮겨집니다.",
        "de": "Tippen zum Bearbeiten. Nach „Bearbeiten“ kannst du sortieren oder löschen. Mindestens eine Kategorie behalten; Abos wechseln zu einer verbleibenden.",
        "fr": "Touchez pour modifier. Après « Modifier », vous pouvez réordonner ou supprimer. Conservez au moins une catégorie ; les abonnements iront dans une restante.",
        "es": "Toca para editar. Tras «Editar» puedes reordenar o eliminar. Conserva al menos una categoría; las suscripciones pasarán a otra restante.",
        "it": "Tocca per modificare. Dopo «Modifica» puoi riordinare o eliminare. Conserva almeno una categoria; gli abbonamenti passeranno a una rimanente.",
        "pt-BR": "Toque para editar. Em «Editar» você pode reordenar ou apagar. Mantenha ao menos uma categoria; as assinaturas irão para outra restante.",
    },
    "iPhone 与 iPad 同步，还可备份到 iCloud 云盘": {
        "en": "Sync iPhone and iPad, and back up to iCloud Drive",
        "zh-Hant": "iPhone 與 iPad 同步，還可備份到 iCloud 雲碟",
        "ja": "iPhone と iPad を同期し、iCloud Drive にもバックアップ",
        "ko": "iPhone과 iPad를 동기화하고 iCloud Drive에 백업",
        "de": "iPhone und iPad synchronisieren und in iCloud Drive sichern",
        "fr": "Synchroniser iPhone et iPad, et sauvegarder sur iCloud Drive",
        "es": "Sincroniza iPhone e iPad y copia en iCloud Drive",
        "it": "Sincronizza iPhone e iPad e fai backup su iCloud Drive",
        "pt-BR": "Sincronize iPhone e iPad e faça backup no iCloud Drive",
    },
    "Renewity 高级会员": {
        "en": "Renewity Pro", "zh-Hant": "Renewity 高級會員", "ja": "Renewity プレミアム",
        "ko": "Renewity 프리미엄", "de": "Renewity Premium", "fr": "Renewity Premium",
        "es": "Renewity Premium", "it": "Renewity Premium", "pt-BR": "Renewity Premium",
    },
    "解锁 Pro。年度或终身。": {
        "en": "Unlock Pro. Yearly or lifetime.",
        "zh-Hant": "解鎖 Pro。年度或終身。",
        "ja": "Pro を解除。年額または買い切り。",
        "ko": "Pro 잠금 해제. 연간 또는 평생.",
        "de": "Pro freischalten. Jährlich oder lebenslang.",
        "fr": "Débloquer Pro. Annuel ou à vie.",
        "es": "Desbloquear Pro. Anual o de por vida.",
        "it": "Sblocca Pro. Annuale o a vita.",
        "pt-BR": "Desbloquear o Pro. Anual ou vitalício.",
    },
    "App Store 未返回套餐。请确认产品已创建，本地调试请在 Scheme 中选用 Products.storekit。": {
        "en": "App Store returned no products. Confirm they exist; for local testing, select Products.storekit in the scheme.",
        "zh-Hant": "App Store 未返回方案。請確認產品已建立，本機偵錯請在 Scheme 中選用 Products.storekit。",
        "ja": "App Store から商品が返りませんでした。作成済みか確認し、ローカルでは Scheme で Products.storekit を選んでください。",
        "ko": "App Store에서 상품이 반환되지 않았습니다. 제품이 있는지 확인하고, 로컬 디버깅은 Scheme에서 Products.storekit을 선택하세요.",
        "de": "Der App Store lieferte keine Produkte. Prüfe, ob sie existieren; lokal Products.storekit im Scheme wählen.",
        "fr": "L’App Store n’a renvoyé aucun produit. Vérifiez qu’ils existent ; en local, choisissez Products.storekit dans le scheme.",
        "es": "App Store no devolvió productos. Confirma que existen; en local, elige Products.storekit en el scheme.",
        "it": "L’App Store non ha restituito prodotti. Verifica che esistano; in locale seleziona Products.storekit nello scheme.",
        "pt-BR": "A App Store não devolveu produtos. Confirme que existem; no teste local, escolha Products.storekit no scheme.",
    },
    "Instagram": same("Instagram"),
    "X": same("X"),
    "https://": same("https://"),
    "法律": {
        "en": "Legal", "zh-Hant": "法律", "ja": "法務",
        "ko": "법률", "de": "Rechtliches", "fr": "Mentions légales",
        "es": "Legal", "it": "Note legali", "pt-BR": "Jurídico",
    },
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def can_generate_swift_symbol(key: str) -> bool:
    """Xcode cannot emit String Catalog symbols unless the key contains a letter or underscore."""
    stripped = re.sub(r"%(?:\d+\$)?(?:ll[ud]|l[ud]|[udif@])", "", key)
    return any(ch == "_" or ch.isalpha() for ch in stripped)


UNUSED_STALE_KEYS = {
    "一次买断，永久解锁",
    "查看分类构成、月均排名和计费方式，把每一笔固定支出看清楚。",
    "按每笔订阅的付款币种，把周期费用折成每月后直接相加，不做汇率换算。试用中还没首次付款的不计入。",
}


def is_stale_glossary_key(key: str) -> bool:
    return "扣费" in key or "扣款" in key or "续费" in key or "币种" in key or key in UNUSED_STALE_KEYS


def dump_xcstrings(path: Path, data: dict) -> None:
    """Keep Xcode's `"key" : {` spacing so a rewrite does not churn the whole catalog."""
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2, separators=(",", " : ")) + "\n",
        encoding="utf-8",
    )


def fill_file(path: Path, upsert_translations: bool = False) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    added = 0
    strings = data.setdefault("strings", {})
    for key in list(strings):
        if not can_generate_swift_symbol(key) or is_stale_glossary_key(key):
            strings.pop(key, None)
    for key, entry in list(strings.items()):
        if not can_generate_swift_symbol(key):
            continue
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
            if not can_generate_swift_symbol(key) or is_stale_glossary_key(key):
                continue
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
    dump_xcstrings(path, data)
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
    print("app added", fill_file(app, upsert_translations=True))
    fill_infoplist(ROOT / "Renewity" / "InfoPlist.xcstrings", "Renewity")


if __name__ == "__main__":
    main()
