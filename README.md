RPG
===

[DXRuby](http://dxruby.sourceforge.jp/)上で動くRPG作成用のライブラリ

を作ろうとしている途中経過を公表すべく、作成されたリポジトリです。

How to Use
---

libフォルダのトップに位置するrpg.rbを`require`して下さい。

その際、DXRubyをrequire出来るようにしていないとErrorになります。また、DXRubyは自動で`require`されるので、自分でDXRubyを`require_relative`するとエラーになります。(`require`なら2回目以降は無視されるので大丈夫です。)

Caution!
---

common/image_marshal.rbをASCIIで保存し直してください。(画像のバイナリを扱っているため、Unicodeでは面倒でした。)