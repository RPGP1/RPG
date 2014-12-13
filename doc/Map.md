What's this?
===

これは、`Map`を理解するためのドキュメントです。

Struction of Map
---

```
Map module
| +-Base class
|
TileSet module
| +-Base class
| |  +-A1 class
| |  +-A2 class
| |  +-A3 class
| |  +-A4 class
| |  +-A5 class
| |  +-B class
| |    (C = D = E = B)
| |
| +-Group class
|
Tile module
  +-Base class
  |  +-Parts1 class
  |  |  +-Water class
  |  |  +-WaterFall class
  |  |
  |  +-DeepSea class
  |  +-Rock class
  |  +-Ground class
  |  +-Buch class
  |  +-Block class
  |  +-Buildings class
  |  |  +-Outside class
  |  |  +-WallTop class
  |  |  +-Wall class
  |  |
  |  +-Pavement class
  |  +-Floor class
  |  +-Upper class
  |
  +-AutotileTile module
  +-SetPatternTile module
  +-WaterFallTile module
  +-OneImageTile module
  |
  +-AnimationTile module

UP, DOWN, LEFT, RIGHT
Direction
```

以下で、下層に存在するモジュール/クラスから説明します。

Tile
---

1種類のタイルの情報をまとめておきます。

`Tile`はタイルに関するクラス・モジュール群を囲っておくためのモジュールです。

`Base`クラスがタイルオブジェクトの基本です。しかし、`Base`クラス単体では機能しません。必要な`set_image`/`size`の2メソッドが定義されていません。これらのメソッドは、ユーザが継承先のクラスで定義するか、後述のモジュールをインクルードします。

`Tile`内のモジュールは全て、`Base`クラスの機能の不足を補うためのモジュールです。

RPGツクールで使用される4パターンの画像処理方法を定義したのが、`AutotileTile`/`SetPatternTile`/`WaterFallTile`/`OneImageTile`です。

`Animation`モジュールはそれらを`include`した後に`include`すると、フレーム数で管理されるタイルアニメーションを使用できます。その際、`include`先の`initialize`内での`super`メソッド呼び出し時に、何フレームでアニメーションを1コマ送るかを指定してください。加えて、`set_image`には`Image`の配列を渡す必要が有ります。

他のクラスはRPGツクール内のタイルの働きを真似る為に作られた、`Base`のサブクラスです。参考にしてください。

タイルには、`@layer`にレイヤー情報を、`@info`ハッシュ内に`:pass`/`land`/`move`の3種の通行情報を保存できます。詳しくは`Tile::Base`の`set_layer`と`set_walkable`を参照してください。

TileSet
---

マップで描画するために、タイルをセットにして管理します。

`.new`では、使用するImageオブジェクトと、タイルセットに対して一意な名前(シンボルまたは文字列)を渡してください。この名前で、TileSetモジュールに特異メソッドが定義され、生成したタイルセットが取り出せるようになります。既にメソッドとして存在している名前を渡すとエラーになります。

`Base`クラスはが全てのタイルセットオブジェクトの基本です。しかし`Tile::Base`同様、単体では機能しません。必要な`set_tile`メソッドが定義されていません。継承先で定義してください。

`set_tile`メソッドを定義する際、以下の事に注意して下さい。

* `set_tile`メソッドは、`.new`に渡された`Image`オブジェクトがそのまま引数として渡されます。
* `set_tile`内ではタイルの生成処理を書いてください。
* タイルの生成には`create_tile`メソッドを利用して下さい。
    * `create_tile`は第一引数に生成するタイルのクラス、それ以降に`.new`に渡す引数を受け取ります。

生成した複数のタイルセットオブジェクトをまとめて扱い、マップ生成時に渡すために、`Group`クラスが有ります。

`Group`クラスは`.new`ができません。タイルセットオブジェクトやタイルセットグループオブジェクトどうしの加算(`+`)によってのみ生成されます。減算(`-`)はできません。

タイルセットオブジェクトは`#save`で保存ができるようになりました。保存したオブジェクトは`TileSet::Base.load_data`でまとめて読み込めます。

Map
---

マップのタイル配列などを管理して描画します。

`Base`クラスがマップオブジェクトの基本ですが、`Map`モジュールに`.new`を定義し、自動で`Tile::Base.new`を呼び出すようにしました。そちらをご利用ください。

`lay`メソッドでタイルを配置する、`loop`でループ設定のハッシュを取り出すなどの機能を持っていますが、現在開発中のマップエディタで生成や編集をするだろうと思われます。

`Map.set`で`Map`モジュールにマップオブジェクトをセットし、`.get`で取得できます。

`Map.draw`でセットしたマップの描画をします。画面の中央にどこのマスを描画するかを、左上を`0`としたマス目のインデックスで指定します。この時の描画先は`Map.target=`で指定でき、描画優先度`z`も`Map.z`で取得できるハッシュを編集することで、レイヤーごとに変更できます。

マップオブジェクトを`#save`で保存ができるようになりました。保存したオブジェクトは`Map::Base.load_data`でまとめて読み込めます。しかし、読み込む際には使用しているタイルセットが既に存在することが必要です。

全般
---

タイルセットとマップのエディタを現在開発中です。