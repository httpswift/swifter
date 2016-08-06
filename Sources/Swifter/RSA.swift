//
//  RSA.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct RSA {
    
    //
    // RSA
    //
    // https://en.wikipedia.org/wiki/RSA_(cryptosystem)
    //
    
    public struct Config {
        public var n, e, d : Int
    }
    
    public static func encrypt(_ s: Int, _ config: Config) -> Int {
        return powmod(s, config.e, config.n);
    }
    
    public static func decrypt(_ c: Int, _ config: Config) -> Int {
        return powmod(c, config.d, config.n);
    }

    public static func config(_ p: Int, _ q: Int) -> Config {
        let n = p * q
        let phin = (p - 1) * (q - 1)
        let e = coprimes(phin)[1]
        let d = inverse(e, phin)
        return Config(n: n, e: e, d: d)
    }

    public static func inverse(_ a: Int, _ n: Int) -> Int {
        for i in 1..<n {
            if (a * i) % n == 1 {
                return i
            }
        }
        return -1
    }
    
    public static func gcd(_ a: Int, _ b: Int) -> Int {
        var r = b, pr = a
        while r > 0 {
            let t = r
            r = pr % r
            pr = t
        }
        return pr;
    }

    public static func coprimes(_ a: Int) -> [Int] {
        var r = [Int]()
        for i in 1..<a {
            if gcd(i, a) == 1 { r.append(i) }
        }
        return r
    }
    
    public static func powmod(_ a: Int, _ b: Int, _ n: Int) -> Int {
        let amod = a % n
        var r = 1
        for _ in 0..<b {
            r = (r * amod) % n
        }
        return r
    }
    
    public static func divisors(_ n: Int) -> [Int] {
        var r = [Int]()
        for i in 0...n {
            if n % i == 0 { r.append(i) }
        }
        return r
    }
    
    public static func factorization(_ n: Int) -> [Int] {
        var nn = n
        var r = [Int]()
        while nn > 1 {
            for d in 2...nn {
                if nn % d == 0 {
                    r.append(d)
                    nn = nn / d
                    break
                }
            }
        }
        return r
    }
    
    public static func phi(_ n: Int) -> Int {
        var r = 1, p = 1
        factorization(n).forEach { f in
            r *= (f != p) ? (f - 1) : f
            p = f
        }
        return r
    }
}

