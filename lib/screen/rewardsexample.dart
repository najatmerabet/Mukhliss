import 'package:flutter/material.dart';

class RewardsStylesScreen extends StatefulWidget {
  const RewardsStylesScreen({Key? key}) : super(key: key);

  @override
  State<RewardsStylesScreen> createState() => _RewardsStylesScreenState();
}

class _RewardsStylesScreenState extends State<RewardsStylesScreen> {
  int userPoints = 45;
  int selectedStyle = 0;

  final List<Reward> rewards = [
    Reward(
      name: '1 Burger Gratuit',
      description: 'Un délicieux burger au choix',
      points: 20,
      icon: Icons.lunch_dining,
      gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade600],
    ),
    Reward(
      name: 'Café Offert',
      description: 'N\'importe quelle boisson chaude',
      points: 10,
      icon: Icons.coffee,
      gradientColors: [Colors.brown.shade400, Colors.brown.shade700],
    ),
    Reward(
      name: 'Pizza Familiale',
      description: 'Pizza large 3 ingrédients',
      points: 50,
      icon: Icons.local_pizza,
      gradientColors: [Colors.red.shade400, Colors.red.shade700],
    ),
    Reward(
      name: 'Dessert au Choix',
      description: 'Gâteau, glace ou tarte',
      points: 15,
      icon: Icons.cake,
      gradientColors: [Colors.pink.shade300, Colors.pink.shade600],
    ),
    Reward(
      name: 'Menu Complet',
      description: 'Plat + Boisson + Dessert',
      points: 40,
      icon: Icons.restaurant,
      gradientColors: [Colors.green.shade400, Colors.green.shade700],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Styles de Récompenses',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$userPoints pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(10, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getStyleName(index)),
                      selected: selectedStyle == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedStyle = index;
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(child: _buildRewardsList()),
        ],
      ),
    );
  }

  String _getStyleName(int index) {
    switch (index) {
      case 0: return 'Cartes Gradient';
      case 1: return 'Liste Compacte';
      case 2: return 'Grille';
      case 3: return 'Cartes 3D';
      case 4: return 'Timeline';
      case 5: return 'Glassmorphism';
      case 6: return 'Néon';
      case 7: return 'Minimaliste';
      case 8: return 'Instagram Story';
      case 9: return 'Bento Grid';
      default: return 'Style $index';
    }
  }

  Widget _buildRewardsList() {
    switch (selectedStyle) {
      case 0: return _buildCardStyle();
      case 1: return _buildListStyle();
      case 2: return _buildGridStyle();
      case 3: return _build3DCardStyle();
      case 4: return _buildTimelineStyle();
      case 5: return _buildGlassmorphismStyle();
      case 6: return _buildNeonStyle();
      case 7: return _buildMinimalistStyle();
      case 8: return _buildStoryStyle();
      case 9: return _buildBentoGridStyle();
      default: return _buildCardStyle();
    }
  }

  // Style 1: Cartes avec gradient (original)
  Widget _buildCardStyle() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canAfford ? reward.gradientColors : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: canAfford ? reward.gradientColors[0].withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canAfford ? () {} : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(reward.icon, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${reward.points} points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        canAfford ? Icons.check_circle : Icons.lock,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Style 2: Liste compacte
  Widget _buildListStyle() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canAfford ? reward.gradientColors : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(reward.icon, color: Colors.white, size: 30),
            ),
            title: Text(
              reward.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: canAfford ? Colors.black87 : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: canAfford ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford ? reward.gradientColors[0].withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: canAfford ? reward.gradientColors[1] : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.points} pts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? reward.gradientColors[1] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Icon(
              canAfford ? Icons.arrow_forward_ios : Icons.lock,
              color: canAfford ? reward.gradientColors[1] : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  // Style 3: Grille
  Widget _buildGridStyle() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canAfford ? () {} : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: canAfford ? reward.gradientColors : [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(reward.icon, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reward.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: canAfford ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reward.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: canAfford ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: canAfford
                            ? LinearGradient(colors: reward.gradientColors)
                            : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.points}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Style 4: Cartes 3D avec ombre profonde
  Widget _build3DCardStyle() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-0.02),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: canAfford ? reward.gradientColors[0].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: canAfford ? reward.gradientColors[1].withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: canAfford
                              ? [reward.gradientColors[0].withOpacity(0.1), reward.gradientColors[1].withOpacity(0.05)]
                              : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: canAfford ? reward.gradientColors : [Colors.grey.shade300, Colors.grey.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: canAfford ? reward.gradientColors[0].withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(reward.icon, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                reward.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                reward.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: canAfford ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: canAfford
                                          ? LinearGradient(colors: reward.gradientColors)
                                          : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.stars, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${reward.points} pts',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          canAfford ? Icons.arrow_forward_ios : Icons.lock,
                          color: canAfford ? reward.gradientColors[1] : Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Style 5: Timeline vertical
  Widget _buildTimelineStyle() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;
        final isLast = index == rewards.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: canAfford
                        ? LinearGradient(colors: reward.gradientColors)
                        : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: canAfford ? reward.gradientColors[0].withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(reward.icon, size: 24, color: Colors.white),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          canAfford ? reward.gradientColors[0].withOpacity(0.5) : Colors.grey.shade300,
                          Colors.grey.shade200,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reward.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: canAfford ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                        Icon(
                          canAfford ? Icons.check_circle : Icons.lock,
                          color: canAfford ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reward.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: canAfford ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: canAfford ? reward.gradientColors[0].withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canAfford ? reward.gradientColors[0].withOpacity(0.3) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: canAfford ? reward.gradientColors[1] : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.points} points requis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: canAfford ? reward.gradientColors[1] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Style 6: Glassmorphism
  Widget _buildGlassmorphismStyle() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.blue.shade400, Colors.pink.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final canAfford = userPoints >= reward.points;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(reward.icon, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reward.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${reward.points} pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: canAfford ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              canAfford ? Icons.check : Icons.lock,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Style 7: Néon
  Widget _buildNeonStyle() {
    return Container(
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final canAfford = userPoints >= reward.points;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: canAfford ? reward.gradientColors[0] : Colors.grey.shade700,
                  width: 2,
                ),
                boxShadow: canAfford
                    ? [
                        BoxShadow(
                          color: reward.gradientColors[0],
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: reward.gradientColors[1],
                          blurRadius: 40,
                          spreadRadius: -10,
                        ),
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: canAfford ? reward.gradientColors[0] : Colors.grey.shade700,
                          width: 2,
                        ),
                        boxShadow: canAfford
                            ? [
                                BoxShadow(
                                  color: reward.gradientColors[0],
                                  blurRadius: 15,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        reward.icon,
                        size: 40,
                        color: canAfford ? reward.gradientColors[0] : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.name,
                            style: TextStyle(
                              color: canAfford ? Colors.white : Colors.grey.shade600,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: canAfford
                                  ? [
                                      Shadow(
                                        color: reward.gradientColors[0],
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reward.description,
                            style: TextStyle(
                              color: canAfford ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: canAfford ? reward.gradientColors[0] : Colors.grey.shade700,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 16,
                                  color: canAfford ? reward.gradientColors[0] : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reward.points} pts',
                                  style: TextStyle(
                                    color: canAfford ? reward.gradientColors[0] : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      canAfford ? Icons.arrow_forward : Icons.lock,
                      color: canAfford ? reward.gradientColors[0] : Colors.grey.shade700,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Style 8: Minimaliste
  Widget _buildMinimalistStyle() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: canAfford ? reward.gradientColors[0] : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: canAfford ? Colors.black87 : Colors.grey,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reward.points} POINTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: canAfford ? reward.gradientColors[1] : Colors.grey,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    reward.icon,
                    size: 32,
                    color: canAfford ? reward.gradientColors[0].withOpacity(0.3) : Colors.grey.shade300,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
            ],
          ),
        );
      },
    );
  }

  // Style 9: Instagram Story
  Widget _buildStoryStyle() {
    return PageView.builder(
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canAfford ? reward.gradientColors : [Colors.grey.shade400, Colors.grey.shade600],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: List.generate(
                    rewards.length,
                    (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == index ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Icon(reward.icon, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      reward.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reward.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            color: canAfford ? reward.gradientColors[1] : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${reward.points} POINTS',
                            style: TextStyle(
                              color: canAfford ? reward.gradientColors[1] : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (canAfford)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'RÉCUPÉRER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'VERROUILLÉ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Glissez pour voir plus →',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Style 10: Bento Grid
  Widget _buildBentoGridStyle() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.points;
        
        // Variations de taille pour un effet Bento
        final isLarge = index % 5 == 0;
        final crossAxisCellCount = isLarge ? 2 : 1;

        return Container(
          decoration: BoxDecoration(
            color: canAfford ? reward.gradientColors[0].withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: canAfford ? reward.gradientColors[0].withOpacity(0.3) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  reward.icon,
                  size: 100,
                  color: canAfford ? reward.gradientColors[0].withOpacity(0.1) : Colors.grey.shade200,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: canAfford
                            ? LinearGradient(colors: reward.gradientColors)
                            : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(reward.icon, size: 28, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      reward.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: canAfford ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.stars,
                          size: 16,
                          color: canAfford ? reward.gradientColors[1] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.points}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: canAfford ? reward.gradientColors[1] : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: canAfford ? reward.gradientColors[0].withOpacity(0.2) : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            canAfford ? Icons.check : Icons.lock,
                            size: 16,
                            color: canAfford ? reward.gradientColors[1] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Reward {
  final String name;
  final String description;
  final int points;
  final IconData icon;
  final List<Color> gradientColors;

  Reward({
    required this.name,
    required this.description,
    required this.points,
    required this.icon,
    required this.gradientColors,
  });
}