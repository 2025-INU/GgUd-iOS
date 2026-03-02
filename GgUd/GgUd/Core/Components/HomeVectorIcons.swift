import SwiftUI

struct HomeLocationPinIcon: View {
    var body: some View {
        HomeLocationPinShape()
            .fill(Color(hex: "#4B5563"))
            .accessibilityHidden(true)
    }
}

struct HomeLocationPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 8.9568, y: 8.96583))
        path.addLine(to: CGPoint(x: 5.24813, y: 12.6758))
        path.addLine(to: CGPoint(x: 1.53945, y: 8.96583))
        path.addCurve(to: CGPoint(x: 0.174938, y: 6.58583),
                      control1: CGPoint(x: 0.863025, y: 8.29695),
                      control2: CGPoint(x: 0.408188, y: 7.50361))
        path.addCurve(to: CGPoint(x: 0.174938, y: 3.92583),
                      control1: CGPoint(x: -0.0583125, y: 5.69917),
                      control2: CGPoint(x: -0.0583125, y: 4.8125))
        path.addCurve(to: CGPoint(x: 1.53362, y: 1.54),
                      control1: CGPoint(x: 0.408188, y: 3.00806),
                      control2: CGPoint(x: 0.861081, y: 2.21278))
        path.addCurve(to: CGPoint(x: 3.9186, y: 0.169168),
                      control1: CGPoint(x: 2.20616, y: 0.867224),
                      control2: CGPoint(x: 3.00115, y: 0.410279))
        path.addCurve(to: CGPoint(x: 6.57765, y: 0.169168),
                      control1: CGPoint(x: 4.80495, y: -0.0563879),
                      control2: CGPoint(x: 5.6913, y: -0.0563879))
        path.addCurve(to: CGPoint(x: 8.96263, y: 1.54),
                      control1: CGPoint(x: 7.4951, y: 0.410279),
                      control2: CGPoint(x: 8.29009, y: 0.867224))
        path.addCurve(to: CGPoint(x: 10.3213, y: 3.92583),
                      control1: CGPoint(x: 9.63517, y: 2.21278),
                      control2: CGPoint(x: 10.0881, y: 3.00806))
        path.addCurve(to: CGPoint(x: 10.3213, y: 6.58583),
                      control1: CGPoint(x: 10.5546, y: 4.8125),
                      control2: CGPoint(x: 10.5546, y: 5.69917))
        path.addCurve(to: CGPoint(x: 8.9568, y: 8.96583),
                      control1: CGPoint(x: 10.0881, y: 7.50361),
                      control2: CGPoint(x: 9.63323, y: 8.29695))
        path.closeSubpath()

        path.move(to: CGPoint(x: 5.24813, y: 6.4225))
        path.addCurve(to: CGPoint(x: 5.83125, y: 6.265),
                      control1: CGPoint(x: 5.45805, y: 6.4225),
                      control2: CGPoint(x: 5.65242, y: 6.37))
        path.addCurve(to: CGPoint(x: 6.25693, y: 5.83917),
                      control1: CGPoint(x: 6.01008, y: 6.16),
                      control2: CGPoint(x: 6.15197, y: 6.01806))
        path.addCurve(to: CGPoint(x: 6.41437, y: 5.25583),
                      control1: CGPoint(x: 6.36189, y: 5.66028),
                      control2: CGPoint(x: 6.41437, y: 5.46583))
        path.addCurve(to: CGPoint(x: 6.25693, y: 4.6725),
                      control1: CGPoint(x: 6.41437, y: 5.04583),
                      control2: CGPoint(x: 6.36189, y: 4.85139))
        path.addCurve(to: CGPoint(x: 5.83125, y: 4.24667),
                      control1: CGPoint(x: 6.15197, y: 4.49361),
                      control2: CGPoint(x: 6.01008, y: 4.35167))
        path.addCurve(to: CGPoint(x: 5.24813, y: 4.08917),
                      control1: CGPoint(x: 5.65242, y: 4.14167),
                      control2: CGPoint(x: 5.45805, y: 4.08917))
        path.addCurve(to: CGPoint(x: 4.665, y: 4.24667),
                      control1: CGPoint(x: 5.0382, y: 4.08917),
                      control2: CGPoint(x: 4.84382, y: 4.14167))
        path.addCurve(to: CGPoint(x: 4.23932, y: 4.6725),
                      control1: CGPoint(x: 4.48618, y: 4.35167),
                      control2: CGPoint(x: 4.34428, y: 4.49361))
        path.addCurve(to: CGPoint(x: 4.08187, y: 5.25583),
                      control1: CGPoint(x: 4.13436, y: 4.85139),
                      control2: CGPoint(x: 4.08187, y: 5.04583))
        path.addCurve(to: CGPoint(x: 4.23932, y: 5.83917),
                      control1: CGPoint(x: 4.08187, y: 5.46583),
                      control2: CGPoint(x: 4.13436, y: 5.66028))
        path.addCurve(to: CGPoint(x: 4.665, y: 6.265),
                      control1: CGPoint(x: 4.34428, y: 6.01806),
                      control2: CGPoint(x: 4.48618, y: 6.16))
        path.addCurve(to: CGPoint(x: 5.24813, y: 6.4225),
                      control1: CGPoint(x: 4.84382, y: 6.37),
                      control2: CGPoint(x: 5.0382, y: 6.4225))
        path.closeSubpath()

        let scaleX = rect.width / 11.0
        let scaleY = rect.height / 13.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

struct HomeDateIcon: View {
    var body: some View {
        HomeDateIconShape()
            .fill(Color(hex: "#4B5563"))
            .accessibilityHidden(true)
    }
}

struct HomeDateIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 4.08187, y: 0))
        path.addLine(to: CGPoint(x: 4.08187, y: 1.16667))
        path.addLine(to: CGPoint(x: 7.58063, y: 1.16667))
        path.addLine(to: CGPoint(x: 7.58063, y: 0))
        path.addLine(to: CGPoint(x: 8.74687, y: 0))
        path.addLine(to: CGPoint(x: 8.74687, y: 1.16667))
        path.addLine(to: CGPoint(x: 11.0794, y: 1.16667))
        path.addCurve(to: CGPoint(x: 11.4934, y: 1.33583),
                      control1: CGPoint(x: 11.2427, y: 1.16667),
                      control2: CGPoint(x: 11.3807, y: 1.22306))
        path.addCurve(to: CGPoint(x: 11.6625, y: 1.75),
                      control1: CGPoint(x: 11.6061, y: 1.44861),
                      control2: CGPoint(x: 11.6625, y: 1.58667))
        path.addLine(to: CGPoint(x: 11.6625, y: 11.0833))
        path.addCurve(to: CGPoint(x: 11.4934, y: 11.4975),
                      control1: CGPoint(x: 11.6625, y: 11.2467),
                      control2: CGPoint(x: 11.6061, y: 11.3847))
        path.addCurve(to: CGPoint(x: 11.0794, y: 11.6667),
                      control1: CGPoint(x: 11.3807, y: 11.6103),
                      control2: CGPoint(x: 11.2427, y: 11.6667))
        path.addLine(to: CGPoint(x: 0.583125, y: 11.6667))
        path.addCurve(to: CGPoint(x: 0.169106, y: 11.4975),
                      control1: CGPoint(x: 0.41985, y: 11.6667),
                      control2: CGPoint(x: 0.281844, y: 11.6103))
        path.addCurve(to: CGPoint(x: 0, y: 11.0833),
                      control1: CGPoint(x: 0.0563687, y: 11.3847),
                      control2: CGPoint(x: 0, y: 11.2467))
        path.addLine(to: CGPoint(x: 0, y: 1.75))
        path.addCurve(to: CGPoint(x: 0.169106, y: 1.33583),
                      control1: CGPoint(x: 0, y: 1.58667),
                      control2: CGPoint(x: 0.0563687, y: 1.44861))
        path.addCurve(to: CGPoint(x: 0.583125, y: 1.16667),
                      control1: CGPoint(x: 0.281844, y: 1.22306),
                      control2: CGPoint(x: 0.41985, y: 1.16667))
        path.addLine(to: CGPoint(x: 2.91563, y: 1.16667))
        path.addLine(to: CGPoint(x: 2.91563, y: 0))
        path.addLine(to: CGPoint(x: 4.08187, y: 0))
        path.closeSubpath()

        path.move(to: CGPoint(x: 10.4963, y: 5.83333))
        path.addLine(to: CGPoint(x: 1.16625, y: 5.83333))
        path.addLine(to: CGPoint(x: 1.16625, y: 10.5))
        path.addLine(to: CGPoint(x: 10.4963, y: 10.5))
        path.addLine(to: CGPoint(x: 10.4963, y: 5.83333))
        path.closeSubpath()

        path.move(to: CGPoint(x: 2.91563, y: 2.33333))
        path.addLine(to: CGPoint(x: 1.16625, y: 2.33333))
        path.addLine(to: CGPoint(x: 1.16625, y: 4.66667))
        path.addLine(to: CGPoint(x: 10.4963, y: 4.66667))
        path.addLine(to: CGPoint(x: 10.4963, y: 2.33333))
        path.addLine(to: CGPoint(x: 8.74687, y: 2.33333))
        path.addLine(to: CGPoint(x: 8.74687, y: 3.5))
        path.addLine(to: CGPoint(x: 7.58063, y: 3.5))
        path.addLine(to: CGPoint(x: 7.58063, y: 2.33333))
        path.addLine(to: CGPoint(x: 4.08187, y: 2.33333))
        path.addLine(to: CGPoint(x: 4.08187, y: 3.5))
        path.addLine(to: CGPoint(x: 2.91563, y: 3.5))
        path.addLine(to: CGPoint(x: 2.91563, y: 2.33333))
        path.closeSubpath()

        let scaleX = rect.width / 12.0
        let scaleY = rect.height / 12.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

struct HomeTimeIcon: View {
    var body: some View {
        HomeTimeIconShape()
            .fill(Color(hex: "#4B5563"))
            .accessibilityHidden(true)
    }
}

struct HomeTimeIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 5.83125, y: 11.6667))
        path.addCurve(to: CGPoint(x: 3.55706, y: 11.2117),
                      control1: CGPoint(x: 5.0382, y: 11.6667),
                      control2: CGPoint(x: 4.28014, y: 11.515))
        path.addCurve(to: CGPoint(x: 1.70856, y: 9.9575),
                      control1: CGPoint(x: 2.86509, y: 10.9161),
                      control2: CGPoint(x: 2.24892, y: 10.4981))
        path.addCurve(to: CGPoint(x: 0.454838, y: 8.10833),
                      control1: CGPoint(x: 1.16819, y: 9.41695),
                      control2: CGPoint(x: 0.750288, y: 8.80056))
        path.addCurve(to: CGPoint(x: 0, y: 5.83333),
                      control1: CGPoint(x: 0.151613, y: 7.385),
                      control2: CGPoint(x: 0, y: 6.62667))
        path.addCurve(to: CGPoint(x: 0.454838, y: 3.55833),
                      control1: CGPoint(x: 0, y: 5.04),
                      control2: CGPoint(x: 0.151613, y: 4.28167))
        path.addCurve(to: CGPoint(x: 1.70856, y: 1.70917),
                      control1: CGPoint(x: 0.750288, y: 2.86611),
                      control2: CGPoint(x: 1.16819, y: 2.24972))
        path.addCurve(to: CGPoint(x: 3.55706, y: 0.455001),
                      control1: CGPoint(x: 2.24892, y: 1.16861),
                      control2: CGPoint(x: 2.86509, y: 0.750557))
        path.addCurve(to: CGPoint(x: 5.83125, y: 0),
                      control1: CGPoint(x: 4.28014, y: 0.151668),
                      control2: CGPoint(x: 5.0382, y: 0))
        path.addCurve(to: CGPoint(x: 8.10544, y: 0.455001),
                      control1: CGPoint(x: 6.6243, y: 0),
                      control2: CGPoint(x: 7.38236, y: 0.151668))
        path.addCurve(to: CGPoint(x: 9.95394, y: 1.70917),
                      control1: CGPoint(x: 8.79741, y: 0.750557),
                      control2: CGPoint(x: 9.41358, y: 1.16861))
        path.addCurve(to: CGPoint(x: 11.2077, y: 3.55833),
                      control1: CGPoint(x: 10.4943, y: 2.24972),
                      control2: CGPoint(x: 10.9122, y: 2.86611))
        path.addCurve(to: CGPoint(x: 11.6625, y: 5.83333),
                      control1: CGPoint(x: 11.5109, y: 4.28167),
                      control2: CGPoint(x: 11.6625, y: 5.04))
        path.addCurve(to: CGPoint(x: 11.2077, y: 8.10833),
                      control1: CGPoint(x: 11.6625, y: 6.62667),
                      control2: CGPoint(x: 11.5109, y: 7.385))
        path.addCurve(to: CGPoint(x: 9.95394, y: 9.9575),
                      control1: CGPoint(x: 10.9122, y: 8.80056),
                      control2: CGPoint(x: 10.4943, y: 9.41695))
        path.addCurve(to: CGPoint(x: 8.10544, y: 11.2117),
                      control1: CGPoint(x: 9.41358, y: 10.4981),
                      control2: CGPoint(x: 8.79741, y: 10.9161))
        path.addCurve(to: CGPoint(x: 5.83125, y: 11.6667),
                      control1: CGPoint(x: 7.38236, y: 11.515),
                      control2: CGPoint(x: 6.6243, y: 11.6667))
        path.closeSubpath()

        path.move(to: CGPoint(x: 5.83125, y: 10.5))
        path.addCurve(to: CGPoint(x: 8.18707, y: 9.85833),
                      control1: CGPoint(x: 6.67872, y: 10.5),
                      control2: CGPoint(x: 7.464, y: 10.2861))
        path.addCurve(to: CGPoint(x: 9.85481, y: 8.19),
                      control1: CGPoint(x: 8.88682, y: 9.44611),
                      control2: CGPoint(x: 9.44274, y: 8.89))
        path.addCurve(to: CGPoint(x: 10.4963, y: 5.83333),
                      control1: CGPoint(x: 10.2824, y: 7.46667),
                      control2: CGPoint(x: 10.4963, y: 6.68111))
        path.addCurve(to: CGPoint(x: 9.85481, y: 3.47667),
                      control1: CGPoint(x: 10.4963, y: 4.98556),
                      control2: CGPoint(x: 10.2824, y: 4.2))
        path.addCurve(to: CGPoint(x: 8.18707, y: 1.80833),
                      control1: CGPoint(x: 9.44274, y: 2.77667),
                      control2: CGPoint(x: 8.88682, y: 2.22056))
        path.addCurve(to: CGPoint(x: 5.83125, y: 1.16667),
                      control1: CGPoint(x: 7.464, y: 1.38056),
                      control2: CGPoint(x: 6.67872, y: 1.16667))
        path.addCurve(to: CGPoint(x: 3.47543, y: 1.80833),
                      control1: CGPoint(x: 4.98378, y: 1.16667),
                      control2: CGPoint(x: 4.1985, y: 1.38056))
        path.addCurve(to: CGPoint(x: 1.80769, y: 3.47667),
                      control1: CGPoint(x: 2.77568, y: 2.22056),
                      control2: CGPoint(x: 2.21976, y: 2.77667))
        path.addCurve(to: CGPoint(x: 1.16625, y: 5.83333),
                      control1: CGPoint(x: 1.38006, y: 4.2),
                      control2: CGPoint(x: 1.16625, y: 4.98556))
        path.addCurve(to: CGPoint(x: 1.80769, y: 8.19),
                      control1: CGPoint(x: 1.16625, y: 6.68111),
                      control2: CGPoint(x: 1.38006, y: 7.46667))
        path.addCurve(to: CGPoint(x: 3.47543, y: 9.85833),
                      control1: CGPoint(x: 2.21976, y: 8.89),
                      control2: CGPoint(x: 2.77568, y: 9.44611))
        path.addCurve(to: CGPoint(x: 5.83125, y: 10.5),
                      control1: CGPoint(x: 4.1985, y: 10.2861),
                      control2: CGPoint(x: 4.98378, y: 10.5))
        path.closeSubpath()

        path.move(to: CGPoint(x: 6.41437, y: 5.83333))
        path.addLine(to: CGPoint(x: 8.74687, y: 5.83333))
        path.addLine(to: CGPoint(x: 8.74687, y: 7))
        path.addLine(to: CGPoint(x: 5.24813, y: 7))
        path.addLine(to: CGPoint(x: 5.24813, y: 2.91667))
        path.addLine(to: CGPoint(x: 6.41437, y: 2.91667))
        path.addLine(to: CGPoint(x: 6.41437, y: 5.83333))
        path.closeSubpath()

        let scaleX = rect.width / 12.0
        let scaleY = rect.height / 12.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

struct HomeAlarmIcon: View {
    var body: some View {
        HomeAlarmIconShape()
            .fill(Color(hex: "#374151"))
            .accessibilityHidden(true)
    }
}

struct HomeAlarmIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 1.6675, y: 13.3333))
        path.addLine(to: CGPoint(x: 13.34, y: 13.3333))
        path.addLine(to: CGPoint(x: 13.34, y: 7.53333))
        path.addCurve(to: CGPoint(x: 12.5396, y: 4.58333),
                      control1: CGPoint(x: 13.34, y: 6.47778),
                      control2: CGPoint(x: 13.0732, y: 5.49444))
        path.addCurve(to: CGPoint(x: 10.4552, y: 2.46667),
                      control1: CGPoint(x: 12.0282, y: 3.69444),
                      control2: CGPoint(x: 11.3334, y: 2.98889))
        path.addCurve(to: CGPoint(x: 7.50375, y: 1.68333),
                      control1: CGPoint(x: 9.54366, y: 1.94444),
                      control2: CGPoint(x: 8.55983, y: 1.68333))
        path.addCurve(to: CGPoint(x: 4.55227, y: 2.46667),
                      control1: CGPoint(x: 6.44767, y: 1.68333),
                      control2: CGPoint(x: 5.46384, y: 1.94444))
        path.addCurve(to: CGPoint(x: 2.4679, y: 4.58333),
                      control1: CGPoint(x: 3.67406, y: 2.98889),
                      control2: CGPoint(x: 2.97927, y: 3.69444))
        path.addCurve(to: CGPoint(x: 1.6675, y: 7.53333),
                      control1: CGPoint(x: 1.9343, y: 5.49444),
                      control2: CGPoint(x: 1.6675, y: 6.47778))
        path.addLine(to: CGPoint(x: 1.6675, y: 13.3333))
        path.closeSubpath()

        path.move(to: CGPoint(x: 7.50375, y: 0))
        path.addCurve(to: CGPoint(x: 11.289, y: 1.03333),
                      control1: CGPoint(x: 8.85998, y: 0),
                      control2: CGPoint(x: 10.1217, y: 0.344444))
        path.addCurve(to: CGPoint(x: 13.9903, y: 3.73333),
                      control1: CGPoint(x: 12.4229, y: 1.7),
                      control2: CGPoint(x: 13.3233, y: 2.6))
        path.addCurve(to: CGPoint(x: 15.0075, y: 7.53333),
                      control1: CGPoint(x: 14.6684, y: 4.9),
                      control2: CGPoint(x: 15.0075, y: 6.16667))
        path.addLine(to: CGPoint(x: 15.0075, y: 15))
        path.addLine(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: 0, y: 7.53333))
        path.addCurve(to: CGPoint(x: 1.01717, y: 3.73333),
                      control1: CGPoint(x: 0, y: 6.16667),
                      control2: CGPoint(x: 0.339058, y: 4.9))
        path.addCurve(to: CGPoint(x: 3.71852, y: 1.03333),
                      control1: CGPoint(x: 1.68417, y: 2.6),
                      control2: CGPoint(x: 2.58462, y: 1.7))
        path.addCurve(to: CGPoint(x: 7.50375, y: 0.0166664),
                      control1: CGPoint(x: 4.88577, y: 0.355556),
                      control2: CGPoint(x: 6.14752, y: 0.0166664))
        path.addLine(to: CGPoint(x: 7.50375, y: 0))
        path.closeSubpath()

        path.move(to: CGPoint(x: 5.41937, y: 15.8333))
        path.addLine(to: CGPoint(x: 9.58812, y: 15.8333))
        path.addCurve(to: CGPoint(x: 9.30465, y: 16.8833),
                      control1: CGPoint(x: 9.58812, y: 16.2111),
                      control2: CGPoint(x: 9.49363, y: 16.5611))
        path.addCurve(to: CGPoint(x: 8.54594, y: 17.65),
                      control1: CGPoint(x: 9.11567, y: 17.2056),
                      control2: CGPoint(x: 8.86276, y: 17.4611))
        path.addCurve(to: CGPoint(x: 7.50375, y: 17.9333),
                      control1: CGPoint(x: 8.22911, y: 17.8389),
                      control2: CGPoint(x: 7.88172, y: 17.9333))
        path.addCurve(to: CGPoint(x: 6.46156, y: 17.65),
                      control1: CGPoint(x: 7.12578, y: 17.9333),
                      control2: CGPoint(x: 6.77839, y: 17.8389))
        path.addCurve(to: CGPoint(x: 5.70285, y: 16.8833),
                      control1: CGPoint(x: 6.14474, y: 17.4611),
                      control2: CGPoint(x: 5.89183, y: 17.2056))
        path.addCurve(to: CGPoint(x: 5.41937, y: 15.85),
                      control1: CGPoint(x: 5.51387, y: 16.5611),
                      control2: CGPoint(x: 5.41937, y: 16.2167))
        path.addLine(to: CGPoint(x: 5.41937, y: 15.8333))
        path.closeSubpath()

        let scaleX = rect.width / 15.0
        let scaleY = rect.height / 18.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}
