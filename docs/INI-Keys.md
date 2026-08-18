# 新增 INI 键文档模板

每新增一个可被 INI 读取的键，请在本文件中追加一条记录，格式如下。
（字段含义与 Phobos 的 `New-or-Enhanced-Logics.md` 对齐，便于迁移与审查。）

---

## `[SectionName]`

### `YourKeyName`

- **默认值**：`false`
- **适用类型**：`TechnoType` / `BuildingType` / `WeaponType` / `Global` / ...
- **取值类型**：`boolean` | `integer` | `double` | `string` | `list`
- **作用对象**：该键影响哪个游戏对象 / 全局行为
- **说明**：用一两句话解释语义。
- **示例**：
  ```ini
  [YourSection]
  YourKeyName=yes
  ```

---

## 示例（模板自带）

### `[FallingStars]`

#### `ExampleEnabled`

- **默认值**：`false`
- **适用类型**：`Global`
- **取值类型**：`boolean`
- **作用对象**：由 `ExampleModule` 在 `LoadFromINI` 中读取，仅作演示。
- **示例**：
  ```ini
  [FallingStars]
  ExampleEnabled=yes
  ```

#### `TechnoTypeExampleFlag`

- **默认值**：`false`
- **适用类型**：`TechnoType`
- **取值类型**：`boolean`
- **作用对象**：由 `TechnoTypeExt::ExtData::LoadFromINIFile` 读取（演示用，写在固定 section）。
- **示例**：
  ```ini
  [FallingStars]
  TechnoTypeExampleFlag=yes
  ```
