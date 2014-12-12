RPG
===

[DXRuby](http://dxruby.sourceforge.jp/)上で動くRPG作成用のライブラリ

を作ろうとしている途中経過を公表すべく、作成されたリポジトリです。

How to Use
---

フォルダ階層のトップに位置するrpg.rbをrequireして下さい。

その際、DXRubyをrequire出来るようにしていないとErrorになります。また、自動でrequireするので自分でDXRubyをrequireしない方が良いと思います。

Caution!
---

common/image_marshal.rbをASCIIで保存し直してください。(画像のバイナリを扱っているため、Unicodeでは面倒でした。)