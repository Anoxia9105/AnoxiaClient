import 'package:flutter/material.dart';

class ThemeTestPage extends StatefulWidget {
  const ThemeTestPage({super.key});

  @override
  State<ThemeTestPage> createState() => _ThemeTestPageState();
}

class _ThemeTestPageState extends State<ThemeTestPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDark = false;
  double _sliderVal = 40;
  bool _switchVal = true;
  Set<String> _selectedSegment = {'A'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. M3 典型的各种 AppBar 样式测试
      appBar: AppBar(
        title: const Text('M3'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _isDark = !_isDark),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基础'),
            Tab(text: '表单'),
            Tab(text: '导航'),
          ],
        ),
      ),

      // 2. 悬浮按钮 (M3 默认是圆角矩形)
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        child: const Icon(Icons.palette),
      ),

      // 3. 底部导航栏 (NavigationBar)
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: '探索'),
          NavigationDestination(icon: Icon(Icons.commute), label: '通勤'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: '收藏'),
        ],
      ),

      body: TabBarView(
        controller: _tabController,
        children: [_buildGeneralTab(), _buildFormTab(), _buildNavTab()],
      ),
    );
  }

  // --- 选项卡1：基础组件 (按钮、卡片、文字) ---
  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('排版系统 (Typography)'),
        Text('Display Large', style: Theme.of(context).textTheme.displayLarge),
        Text(
          'Headline Medium',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
        Text(
          'Body Medium (默认正文样式)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text('Label Small', style: Theme.of(context).textTheme.labelSmall),

        _sectionTitle('M3 按钮全家桶 (Buttons)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Tonal (色调)'),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
          ],
        ),

        _sectionTitle('分段按钮 (Segmented Buttons)'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'A',
              label: Text('选项 A'),
              icon: Icon(Icons.calendar_view_day),
            ),
            ButtonSegment(
              value: 'B',
              label: Text('选项 B'),
              icon: Icon(Icons.calendar_view_month),
            ),
          ],
          selected: _selectedSegment,
          onSelectionChanged: (set) => setState(() => _selectedSegment = set),
        ),

        _sectionTitle('M3 三大卡片变体 (Cards)'),
        const Card(child: ListTile(title: Text('Elevated Card (默认带阴影)'))),
        const Card(child: ListTile(title: Text('Filled Card (填充颜色)'))),
        const Card(child: ListTile(title: Text('Outlined Card (带边框)'))),
      ],
    );
  }

  // --- 选项卡2：表单与交互 ---
  Widget _buildFormTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('输入与搜索 (Inputs)'),
        const SearchBar(leading: Icon(Icons.search), hintText: 'M3 标准搜索栏...'),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: '外边框模式',
            prefixIcon: Icon(Icons.person),
          ),
        ),

        _sectionTitle('选择器 (Selection)'),
        SwitchListTile(
          title: const Text('开关状态测试'),
          value: _switchVal,
          onChanged: (v) => setState(() => _switchVal = v),
        ),
        Slider(
          value: _sliderVal,
          max: 100,
          divisions: 5,
          label: _sliderVal.round().toString(),
          onChanged: (v) => setState(() => _sliderVal = v),
        ),

        _sectionTitle('指示器 (Indicators)'),
        const Badge(label: Text('3'), child: Icon(Icons.notifications)),
        const SizedBox(height: 20),
        const LinearProgressIndicator(),
      ],
    );
  }

  // --- 选项卡3：高级与反馈 ---
  Widget _buildNavTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('各种 Chip 标签'),
        Wrap(
          spacing: 8,
          children: [
            const FilterChip(
              label: Text('Filter'),
              selected: true,
              onSelected: null,
            ),
            const ChoiceChip(label: Text('Choice'), selected: false),
            InputChip(label: const Text('Delete me'), onDeleted: () {}),
            ActionChip(label: const Text('Action'), onPressed: () {}),
          ],
        ),

        _sectionTitle('弹窗与列表'),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          title: const Text('测试主题背景色'),
          subtitle: const Text('ListTile 使用 surfaceContainer 颜色'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
