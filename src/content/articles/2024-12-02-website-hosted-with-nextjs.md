---
title: "Next.jsでマークダウンで書けるブログページをホスティングや！"
date: "2024-12-02"
description: "君も思うだろう？マークダウンでブログを書きたいなって。"
tags: ["Web", "Next.js", "React", "Markdown"]
---

やぁ、こんにちは。ゃーです。

いやあ、ギリギリ間に合いました。

[mizuame](https://x.com/mizuameisgod)
君の記事に引き続き、これは
[coins Advent Calendar 2024](https://adventar.org/calendars/10367)
2日目記事なのです。

## staticなブログを感動のNextで

なんとこのブログページは
[Next.js](https://nextjs.org)
で書かれており、しかも
[Vercel](https://vercel.com)
に簡単にデプロイできることで知られているにもかかわらず、
[Dの一族](https://x.com/dnobori)
の力で構築されたオンプレサーバ上でセルフホストしています。

このアドベントカレンダーの企画が立ったとき、
さすがにブログくらいは自分で書かにゃならんなあと思い、
夏休みくらいにReact+
[Vite](https://vite.dev)
で妥当なシングルページを作りかけて放置していたところを、
ちょっとNextに興味あるなあと思い、破壊してNext.jsに書き換えたのでした。

## ソースコード

このページのソースコードは
[GitHub](https://github.com/reversed-R/homepage)
に上がっているので、見たい人は見てどうぞ。
改善点など指摘してください。

## ブログはマークダウンで書きたいところ

せっかくブログページを作るならマークダウンで書けるのが理想でしょう。

markdown -> htmlパーサを自作してもいいですが、今回は時間がなかったので先人の力を頼ることにしました。

世の中にはたくさんのそういうパーサがあるらしいですが、
何が正しいのかわからなかったので、
[react-markdown](https://github.com/remarkjs/react-markdown)
というやつを使いました。

```Viewer.tsx
import ReactMarkdown from "react-markdown";
import styles from "./viewer.module.css";

type Props = {
  mdData: string;
};

export default function Viewer(props: Props) {
  return (
    <div className={styles.viewer}>
      <ReactMarkdown>{props.mdData}</ReactMarkdown>
    </div>
  );
}
```

`<ReactMarkdown>{markdownString}</ReactMarkdown>`とするだけで勝手にhtmlにしてくれます、いい話。

以下は元のマークダウンとパース後です。

```
# 大見出し(h1)はこんな感じ

## h2見出し

### h3見出し

###### h6見出し

_斜体_

**太字**

~~打ち消し線~~

> 引用

インラインのコードは`こうだ!`

複数行コードは、

\`\`\`
int main(void){
  printf("Hello, World!\n");
  return 0;
}
\`\`\`

こう。

[リンクとか](https://reversed-r.dev)

テーブル

| 左寄せ   | 中央揃え |   右寄せ |
| :------- | :------: | -------: |
| 左に     | 真ん中に |     右に |
| 寄って   |  揃って  |   寄って |
| いるはず | いるはず | いるはず |

だいたいこんな感じ。
```

# 大見出し(h1)はこんな感じ

## h2見出し

### h3見出し

###### h6見出し

_斜体_

**太字**

~~打ち消し線~~

> 引用

インラインのコードは`こうだ!`

複数行コードは、

```
int main(void){
  printf("Hello, World!\n");
  return 0;
}
```

こう。

[リンクとか](https://reversed-r.dev)

テーブル

| 左寄せ   | 中央揃え |   右寄せ |
| :------- | :------: | -------: |
| 左に     | 真ん中に |     右に |
| 寄って   |  揃って  |   寄って |
| いるはず | いるはず | いるはず |

だいたいこんな感じ。

---

なんと、打ち消し線とテーブルは上手くできてないですね、改善の余地あり。

## Next的感想

結局ブログという静的ページをNextで作るオーバーエンジニアリングをした感想としては、
`use client/server`ようわからん、とか、App Routerとは？と言った感じで、まあ勉強にはなったが、Nextの旨味を享受できてないなというところです。

まあ、その中でもNext的ちょっと面白い実装の部分を、せっかくなんで紹介しておきましょう。

ブログの記事ページを
格納されているそれぞれのマークダウンファイルから
それぞれ1つのパスとして生やしたいとき、

[Dynamic Routes](https://nextjs-ja-translation-docs.vercel.app/docs/routing/dynamic-routes)
という機構でうまいこと解決できるという話です。

次のように`articles/`以下に`articleId/index.md`がおのおのあるとして、

```
blog/
  articles/
    [slug]/
      page.tsx
    article1/
      index.md
    article2/
      index.md
    article3/
      index.md
```

`[slug]`のようにブラケット記法を使って作られたディレクトリまたはファイルが、
その代表となって同種のパスを生成してくれます。

これと[generateStaticParams](https://ja.next-community-docs.dev/docs/app/api-reference/functions/generate-static-params)
を組み合わせて使うことで、
ビルド時にすでに存在する記事を生成しておき、
追加された記事に対して初めてリクエストが来たとき、新たに対応するパスを生成することができます。

```
import fs from "fs";
import path from "path";
import Viewer from "../../components/Viewer.tsx";

export const generateStaticParams = async () => {
  const articles = fs.readdirSync(
    path.resolve(process.cwd(), "app/blog/articles/"),
  );

  return articles
    .filter((dir) => dir !== "[slug]")
    .map((article) => ({
      slug: article,
    }));
};

const getMdData = (articleId: string): string => {
  const mdData = fs
    .readFileSync(
      path.resolve(process.cwd(), "app/blog/articles/", articleId, "index.md"),
    )
    .toString();

  return mdData;
};

const Page = async ({ params }: { params: Promise<{ slug: string }> }) => {
  const slug: string = (await params).slug;
  const mdData = getMdData(slug);

  return (
    <Viewer mdData={mdData} />
  );
};

export default Page;
```

こんな感じです。

## さあ、デプロイだ

かくして（かなり端折りましたが）、なんとかそれっぽいブログページの実装は終わりました。

さあ、セルフホストしているサーバにデプロイするかと思ったところ、
NextはVercelにデプロイする例などが多く、
オンプレの知見が比較的少ないようですね。
インターネットの海を覗いてみてもあまりこういう例は出てこず、Nextの位置づけってそんな感じかあとなりました、
まあNextで静的なブログ、それをセルフホスティング、って変だよな、普通に。

それでもア・ドベントカレンダー当日は迫ってくるので、さっさと動かさにゃなりません。

一応
[ここ](https://ja.next-community-docs.dev/docs/app/building-your-application/deploying#docker-image)
にdockerコンテナでNextを動かす方法がちょろっと書いてあります。

そのままもってきた`Dockerfile`は次のとおり。

```Dockerfile
# syntax=docker.io/docker/dockerfile:1

FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci --legacy-peer-deps; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi


# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN \
  if [ -f yarn.lock ]; then yarn run build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

### https-portal

特にSSL証明書周りどうするの、Apacheをリバースプロキシ？とかにしてサーバ内のNextサーバにリダイレクトか？
などと考えていたところ（もっと本番環境での運用を先に考えろという話はある）、
[powerfulfamily.net](https://powerfulfamily.net)であるところの[間瀬bb](https://x.com/bb_mase)が現れ、
[https-portal](https://github.com/SteveLTN/https-portal)が簡単で良いとのことだったのでやってみました。

https-portalは、`docker-compose.yml`に適当に設定を書いてやるだけで、
Nextのコンテナに対してうまいことプロキシしてくれるはずで、

```docker-compose.yml
services:
  https-portal:
    image: steveltn/https-portal:1
    ports:
      - "80:80"
      - "443:443"
    links:
      - web
    restart: always
    environment:
      DOMAINS: "reversed-r.dev -> http://web:3000"
      STAGE: "production" # Don't use production until staging works

  web:
    build: .
    ports:
      - "3000:3000"
```

こうやったら上手くいくはず！でしたが、動きませんでした。
こうしろ！ポイントがあれば誰か教えてください。

### traefik

https-portalようわからんを半日くらい続けているうちに、
アド・ベントカレンダー当日になり、
[traefik](https://traefik.io/)
というののほうが正統派かもみたいな話もあったなあと思い出し、やってみました。

なんかtra↑efikくんはリバースプロキシとしてシンプルかつ必要十分に優秀らしく、
traefikから参照される旨を`docker-compose.yml`に記しておいたコンテナを上手く回収してまとめてくれるそうです。

がしかし、今回は即席かつこのWebページのみ運用できればいいので、
Nextの`docker-compose.yml`に次のように付け加えるなどし、

```docker-compose.yml
services:
  web:
    build: .
    labels:
      - "traefik.http.routers.web.rule=Host(`reversed-r.dev`)"
  traefik:
    image: traefik:2.0
    ports:
      - 8000:8080 # webUI
      - 80:80
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config/traefik/traefik.yml:/etc/traefik/traefik.yml
```

`config/traefik/traefik.yml`に

```traefik.yml
# Providers config
providers:
  docker: {} # Docker との連携を有効

entryPoints:
  web:
    address: ":80"

  web-secure:
    address: ":443"

certificatesResolvers:
  sample:
    acme:
      email: webmaster@myserver.test
      storage: acme.json
      httpChallenge:
        entryPoint: web
```

と書くと、

なんと感動できることに無事動き、HTTPSにもなったのでした。

## 締め

いや〜、アドベ・ントカレンダーの早い方にぶち込んだほうが良いに決まってるなどという思考で2日目に入れたのが良くなかったですね。
[ベア君](https://x.com/bear_wash9663)にもめちゃくちゃ催促されていますし、
ここらで公開しましょう。

明日は欠番ですが、明後日は他大学生にしてcoinsを騙っているという[brsywe](https://x.com/brsywe)さんの記事です。
楽しみですね〜。
