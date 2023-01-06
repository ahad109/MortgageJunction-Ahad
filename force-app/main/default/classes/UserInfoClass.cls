/**
* @description       :
* @author            : M Hamza Siddiqui
* @group             :
* @last modified on  : 06-14-2022
* @last modified by  : M Hamza Siddiqui
**/
public with sharing class UserInfoClass {
    @AuraEnabled(cacheable=true)
    public static List<User> getUserList() {
        // Checking Permissions before Query
        FilogixWrapperBinding.permChecker(
            'User',
            'Id, Name, Email, Username,Filogix_Id__c,profile.name',
            'read'
        );
        return [
            SELECT Id, Name, Email, Username, Filogix_Id__c, profile.name
            FROM User
            WHERE IsActive = TRUE AND Profile.UserType = 'Standard'
        ];
    }
    
    @AuraEnabled
    public static LIST<sObject> getUserInfo() {
        try {
            // Checking Permissions before Query
            FilogixWrapperBinding.permChecker(
                'User',
                'NAME,EMAIL,Department,CompanyName,Filogix_Id__c,profile.name',
                'read'
            );
            String query = 'SELECT NAME,EMAIL,Department,CompanyName,Filogix_Id__c,profile.name FROM USER WHERE profile.name != NULL WITH SECURITY_ENFORCED';
            LIST<sObject> userlist = database.query(String.escapeSingleQuotes(query));
            System.debug('User List is ' + userlist);
            return userlist;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(
        String searchTerm,
        List<String> selectedIds
    ) {
        try {
            System.debug('selectedIds::' + selectedIds);
            System.debug(searchTerm);
            // Prepare query paramters
            String searchFor = '%' + searchTerm + '%';
            
            System.debug(searchFor);
            // Execute search query
            
            String profileType = 'Standard';
            String query = 'SELECT NAME,EMAIL,Department,CompanyName,Filogix_Id__c,profile.name FROM USER WHERE profile.name != NULL AND id NOT IN :selectedIds AND Name like:searchFor AND IsActive = true AND UserType =: profileType';
            query += ' WITH SECURITY_ENFORCED';
            System.debug('Query::' + query);
            // Checking Permissions before Query
            FilogixWrapperBinding.permChecker(
                'User',
                'NAME,EMAIL,Department,CompanyName,Filogix_Id__c,profile.name',
                'read'
            );
            LIST<sObject> searchResults = database.query(
                String.escapeSingleQuotes(query)
            );
            
            List<LookupSearchResult> results = new List<LookupSearchResult>();
            
            if (searchResults != null && searchResults.size() > 0) {
                System.debug(searchResults);
                
                for (sObject tempUser : searchResults) {
                    results.add(
                        new LookupSearchResult(
                            (String) tempUser.get('Id'),
                            (String) tempUser.get('Name'),
                            'standard:user',
                            (String) tempUser.get('Name'),
                            (String) tempUser.get('EMAIL') +
                            ' - ' +
                            (String) tempUser.getSobject('Profile').get('Name')
                        )
                    );
                }
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateUserInfo(List<User> usrList) {
        try {
            update usrList;
            return 'Sucessfully Updated ' + usrList.size() + ' Users';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateUsers(Object data) {
        List<User> usersForUpdate = (List<User>) JSON.deserialize(
            JSON.serialize(data),
            List<User>.class
        );
        System.debug('usersForUpdate:: ' + usersForUpdate);
        try {
            update usersForUpdate;
            return 'Success: mapping updated successfully';
        } catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }
    
    public class LookupSearchResult {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String icon { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String subtitle { get; set; }
        
        public LookupSearchResult(
            Id userId,
            String usertitle,
            String userIcon,
            String userName,
            String userSubtitle
        ) {
            Id = userId;
            icon = userIcon;
            title = usertitle;
            name = userName;
            subtitle = userSubtitle;
        }
    }
    
    public class FilogixUsersResult {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Email { get; set; }
        @AuraEnabled
        public String UserType { get; set; }
        @AuraEnabled
        public String SmallPhotoUrl { get; set; }
        @AuraEnabled
        public String FilogixId { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FilogixUsersResult> getFilogixUsers() {
        List<FilogixUsersResult> flUsers = new List<FilogixUsersResult>();
        List<User> users = [
            SELECT Name, Email, UserType, SmallPhotoUrl, Filogix_Id__c
            FROM User
            WHERE UserType = 'Standard' OR UserType = 'PowerPartner'
        ];
        //   WITH SECURITY_ENFORCED
        
        for (User user : users) {
            FilogixUsersResult flUser = new FilogixUsersResult();
            flUser.Id = (String) user.Id;
            flUser.Name = (String) user.Name;
            flUser.Email = (String) user.Email;
            flUser.UserType = (String) user.UserType;
            flUser.SmallPhotoUrl = (String) user.SmallPhotoUrl;
            flUser.FilogixId = (String) user.Filogix_Id__c;
            flUsers.add(flUser);
        }
        
        System.debug(flUsers[0]);
        
        return flUsers;
    }
    
    @AuraEnabled
    public static Boolean saveFilogixUser(String userId, String filogixId) {
        User userToUpdate;
        
        try {
            userToUpdate = new User();
            userToUpdate.Id = userId;
            if (filogixId.length() != 0) {
                userToUpdate.Filogix_Id__c = filogixId;
            } else {
                userToUpdate.Filogix_Id__c = null;
            }
            update userToUpdate;
        } catch (DmlException e) {
            String errorMsg = e.getMessage();
            System.debug('An unexpected error has occurred: ' + errorMsg);
            System.debug(e.getDmlType(0));
            throw new AuraHandledException(ErrorMsg);
        }
        
        return true;
    }
    
    @AuraEnabled
    public static Boolean deleteFilogixUser(String userId) {
        return saveFilogixUser(userId, '');
    }
}