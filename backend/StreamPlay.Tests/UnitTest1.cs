using StreamPlay.Api.Helpers;

namespace StreamPlay.Tests;

public class UnitTest1
{
    [Fact]
    public void OtpGenerator_Generates_6_Digit_Code()
    {
        var gen = new OtpGenerator();
        var otp = gen.Generate6Digits();

        Assert.Matches(@"^\d{6}$", otp);
    }
}