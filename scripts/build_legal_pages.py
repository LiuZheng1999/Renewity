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


def document_page(kind: str, code: str, native_title: str, markdown: str) -> str:
    other = "terms" if kind == "privacy" else "privacy"
    other_label = "Terms of Use" if kind == "privacy" else "Privacy Policy"
    body_html = md_to_html(markdown)
    inner = f"""
<header>
  <a class="brand" href="../">Renewity</a>
  <nav>
    <a href="../{kind}/">{"Privacy" if kind == "privacy" else "Terms"}</a>
    <a href="../{other}/">{other_label}</a>
  </nav>
</header>
<main>
  <div class="card">
    {lang_nav(kind, code)}
    {body_html}
  </div>
</main>
<footer>Renewity legal documents · GitHub Pages</footer>
"""
    return page(f"{native_title} · Renewity", inner)


def build_pages() -> None:
    (DOCS / "privacy").mkdir(parents=True, exist_ok=True)
    (DOCS / "terms").mkdir(parents=True, exist_ok=True)
    (DOCS / ".nojekyll").write_text("", encoding="utf-8")

    for kind, prefix, fallback_title in (
        ("privacy", "PrivacyPolicy", "Privacy Policy"),
        ("terms", "TermsOfUse", "Terms of Use"),
    ):
        for code, _label, privacy_title, terms_title in LANGS:
            native = privacy_title if kind == "privacy" else terms_title
            md = (LEGAL / f"{prefix}-{code}.md").read_text(encoding="utf-8")
            (DOCS / kind / f"{code}.html").write_text(
                document_page(kind, code, native, md), encoding="utf-8"
            )
        (DOCS / kind / "index.html").write_text(
            page(
                fallback_title,
                f"""<p>Redirecting…</p>
<script>
const map = {{'zh-CN':'zh-Hans','zh-SG':'zh-Hans','zh-TW':'zh-Hant','zh-HK':'zh-Hant','zh-MO':'zh-Hant','zh-Hant':'zh-Hant','zh':'zh-Hans','ja':'ja','ko':'ko','de':'de','fr':'fr','es':'es','it':'it','pt':'pt-BR','pt-BR':'pt-BR'}};
const tag = (navigator.languages && navigator.languages[0] || navigator.language || 'en');
let code = 'en';
for (const [prefix, value] of Object.entries(map)) {{
  if (tag.toLowerCase().startsWith(prefix.toLowerCase())) {{ code = value; break; }}
}}
location.replace('./' + code + '.html');
</script>
<noscript><a href="./en.html">English</a></noscript>""",
            ),
            encoding="utf-8",
        )

    tiles = "".join(
        f'<a class="tile" href="./privacy/{code}.html"><strong>{html.escape(label)}</strong><span class="muted">{html.escape(p)} · {html.escape(t)}</span></a>'
        for code, label, p, t in LANGS
    )
    index_body = f"""
<header>
  <a class="brand" href="./">Renewity</a>
  <nav>
    <a href="./privacy/">Privacy Policy</a>
    <a href="./terms/">Terms of Use</a>
  </nav>
</header>
<main>
  <h1>Renewity legal</h1>
  <p class="muted">These pages match the in-app Privacy Policy and Terms of Use. Enable GitHub Pages with the <code>docs</code> folder.</p>
  <p><a href="./privacy/">Privacy Policy</a> · <a href="./terms/">Terms of Use</a></p>
  <h2>Languages</h2>
  <div class="grid">{tiles}</div>
</main>
<footer>Questions: philiptrip1975@gmail.com</footer>
"""
    (DOCS / "index.html").write_text(page("Renewity legal", index_body), encoding="utf-8")
    (DOCS / "README.md").write_text(
        f"""# GitHub Pages 法律文档

这个 `docs/` 目录可以直接作为 GitHub Pages 站点发布，内容与应用内《隐私政策》《使用条款》一致。

## 发布步骤

1. 把仓库推送到 GitHub（建议仓库名 `Renewity`）。
2. 打开仓库 **Settings → Pages**。
3. Build and deployment 选 **Deploy from a branch**。
4. Branch 选 `main`，文件夹选 `/docs`，保存。
5. 几分钟后打开：`{WEBSITE}/`

如果 GitHub 用户名不是 `LiuZheng1999`，或仓库名不是 `Renewity`，请同时改：

- `Renewity/Utilities/AppConfig.swift` 里的 `legalWebsiteURL`
- `Renewity/Legal/` 下各语言文档中的网址
- 然后重新运行 `python3 scripts/build_legal_pages.py`

应用「关于」页的「隐私政策（网页）」「使用条款（网页）」会打开上述地址。
""",
        encoding="utf-8",
    )


def main() -> None:
    patch_markdown()
    build_pages()
    print("legal pages written to", DOCS)


if __name__ == "__main__":
    main()
