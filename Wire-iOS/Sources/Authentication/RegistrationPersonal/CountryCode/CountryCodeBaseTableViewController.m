// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "CountryCodeBaseTableViewController.h"
#import "Country.h"



NSString * const CountryCodeCellIdentifier = @"CountryCodeCellIdentifier";



@interface CountryCell : UITableViewCell

@end



@implementation CountryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end



@interface CountryCodeBaseTableViewController ()

@end

@implementation CountryCodeBaseTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[CountryCell class] forCellReuseIdentifier:CountryCodeCellIdentifier];
}

- (void)configureCell:(UITableViewCell *)cell forCountry:(Country *)country
{
    cell.textLabel.text = country.displayName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@", country.e164];
    cell.accessibilityHint = NSLocalizedString(@"registration.phone.country_code.hint", @"");
}

@end
